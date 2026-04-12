/* eslint-disable no-restricted-syntax */
import { createInfiniteQuery } from "@tanstack/solid-query";
import { getBlockNumber, getContractEvents, readContract, watchContractEvent } from "@wagmi/solid/actions";
import { anvil, sepolia } from "@wagmi/solid/chains";
import { createEffect, onCleanup } from "solid-js";
import { ABI, getOffers } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];
type OffersPage = {
  offers: Offer[];
  hasMore: boolean;
};
type SupportedChainId = typeof anvil.id | typeof sepolia.id;

const PAGE_SIZE = 25n;
const REPLAY_HEALTH_CHECK_INTERVAL = 30_000;
const MAX_REPLAY_BLOCK_WINDOW = 2000n;

const decodeOfferTuple = (offer: readonly [
  bigint,
  number,
  number,
  `0x${string}`,
  `0x${string}`,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
]): Offer => ({
  id: offer[0],
  kind: offer[1],
  state: offer[2],
  owner: offer[3],
  counterparty: offer[4],
  amount: offer[5],
  deposit: offer[6],
  price: offer[7],
  lastupdate: offer[8],
  blockTaken: offer[9],
  evmPublicSpendKey: offer[10],
  evmPrivateSpendKey: offer[11],
  evmPublicViewKey: offer[12],
  evmPrivateViewKey: offer[13],
  xmrPublicSpendKey: offer[14],
  xmrPrivateSpendKey: offer[15],
  xmrPrivateViewKey: offer[16],
  t0: offer[17],
  t1: offer[18],
});

const upsertOfferInPages = (pages: OffersPage[], offer: Offer): OffersPage[] => {
  let existsInPages = false;

  const nextPages = pages.map((page) => {
    let changed = false;
    const nextOffers = page.offers
      .map((entry) => {
        if (entry.id !== offer.id) return entry;

        existsInPages = true;
        changed = true;

        return offer;
      })
      .filter(entry => entry.state !== 0);

    if (!changed) return page;

    return {
      ...page,
      offers: nextOffers,
    };
  });

  if (existsInPages || offer.state === 0 || nextPages.length === 0) {
    return nextPages;
  }

  const firstPage = nextPages[0]!;
  const maxLoadedOfferId = firstPage.offers[0]?.id;

  if (maxLoadedOfferId === undefined || offer.id > maxLoadedOfferId) {
    return [
      {
        ...firstPage,
        offers: [offer, ...firstPage.offers].slice(0, Number(PAGE_SIZE)),
      },
      ...nextPages.slice(1),
    ];
  }

  return nextPages;
};

export const useOffers = () => {
  const { chainId, contractAddress } = useApp();

  const query = createInfiniteQuery(() => ({
    queryKey: queryKeys.offers.all(chainId()!),
    queryFn: async ({ pageParam }) => {
      const nextOfferId = await readContract(config, {
        abi: ABI,
        functionName: "nextOfferId",
        address: contractAddress() as `0x${string}`,
        chainId: chainId()!,
      });

      const totalOffers = nextOfferId > 0n ? nextOfferId - 1n : 0n;
      const pageIndex = BigInt(pageParam);
      const pageEnd = totalOffers - pageIndex * PAGE_SIZE;

      if (pageEnd <= 0n) {
        return {
          offers: [],
          hasMore: false,
        } satisfies OffersPage;
      }

      const pageStart = pageEnd > PAGE_SIZE ? pageEnd - PAGE_SIZE : 0n;
      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [pageStart, pageEnd - pageStart, false],
        address: contractAddress() as `0x${string}`,
        chainId: chainId()!,
      });

      const offersFiltered = offers
        .filter(offer => offer.state !== 0)
        .reverse();

      for (const offer of offersFiltered) {
        const stale = queryClient.getQueryData(queryKeys.offers.single(chainId()!, offer.id));

        if (JSON.stringify(stale) === JSON.stringify(offer)) {
          continue;
        }

        queryClient.setQueryData(queryKeys.offers.single(chainId()!, offer.id), () => offer);
      }

      return {
        offers: offersFiltered,
        hasMore: pageStart > 0n,
      } satisfies OffersPage;
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => (lastPage.hasMore ? pages.length : undefined),
    staleTime: Number.POSITIVE_INFINITY,
    refetchOnWindowFocus: false,
    refetchOnReconnect: false,
  }));

  createEffect(() => {
    const currentChainId = chainId() as SupportedChainId | undefined;
    const address = contractAddress();
    let lastSyncedBlock: bigint | undefined;
    let replayRunning = false;

    const refetchSnapshot = async () => {
      await query.refetch();
      lastSyncedBlock = await getBlockNumber(config, { chainId: currentChainId! });
    };

    const applyOfferUpdate = async (offerId: bigint) => {
      const offerRaw = await readContract(config, {
        abi: ABI,
        functionName: "offers",
        args: [offerId],
        address: address as `0x${string}`,
        chainId: currentChainId!,
      });
      const offer = decodeOfferTuple(offerRaw);

      queryClient.setQueryData(queryKeys.offers.single(currentChainId!, offerId), () => offer);
      queryClient.setQueryData(queryKeys.offers.all(currentChainId!), (stale: { pages: OffersPage[]; pageParams: number[]; } | undefined) => {
        if (!stale) return stale;

        return {
          ...stale,
          pages: upsertOfferInPages(stale.pages, offer),
        };
      });
    };

    const replaySinceLastSyncedBlock = async () => {
      if (replayRunning || lastSyncedBlock === undefined) return;

      replayRunning = true;

      try {
        const latestBlock = await getBlockNumber(config, { chainId: currentChainId! });

        if (latestBlock <= lastSyncedBlock) return;

        const fromBlock = lastSyncedBlock + 1n;
        const gap = latestBlock - fromBlock;

        if (gap > MAX_REPLAY_BLOCK_WINDOW) {
          await refetchSnapshot();

          return;
        }

        const logs = await getContractEvents(config, {
          abi: ABI,
          eventName: "OfferEvent",
          address,
          chainId: currentChainId!,
          fromBlock,
          toBlock: latestBlock,
        });

        const changedOfferIds = [...new Set(logs
          .map(log => log.args.offer_id)
          .filter((offerId): offerId is bigint => offerId !== undefined))];

        await Promise.all(changedOfferIds.map(offerId => applyOfferUpdate(offerId)));

        lastSyncedBlock = latestBlock;
      }
      catch {
        await refetchSnapshot();
      }
      finally {
        replayRunning = false;
      }
    };

    if (!currentChainId || !address) return;

    void (async () => {
      lastSyncedBlock = await getBlockNumber(config, { chainId: currentChainId });
      await replaySinceLastSyncedBlock();
    })();

    const unwatch = watchContractEvent(config, {
      abi: ABI,
      address,
      chainId: currentChainId,
      eventName: "OfferEvent",
      onLogs: (logs) => {
        if (logs.length === 0) return;

        const offerIds = [...new Set(logs
          .map(log => log.args.offer_id)
          .filter((offerId): offerId is bigint => offerId !== undefined))];
        const maxBlockInBatch = logs.reduce<bigint | undefined>((max, log) => {
          if (max === undefined || log.blockNumber > max) return log.blockNumber;

          return max;
        }, lastSyncedBlock);

        void Promise.all(offerIds.map(offerId => applyOfferUpdate(offerId))).then(() => {
          if (maxBlockInBatch !== undefined) {
            lastSyncedBlock = maxBlockInBatch;
          }
        });
      },
      onError: () => {
        void replaySinceLastSyncedBlock();
      },
    });

    const healthCheck = setInterval(() => {
      void replaySinceLastSyncedBlock();
    }, REPLAY_HEALTH_CHECK_INTERVAL);

    onCleanup(() => {
      unwatch();
      clearInterval(healthCheck);
    });
  });

  return query;
};
