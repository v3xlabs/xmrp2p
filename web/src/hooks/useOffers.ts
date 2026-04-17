/* eslint-disable no-restricted-syntax */
import { createInfiniteQuery } from "@tanstack/solid-query";
import { getBlockNumber, getContractEvents, readContract, watchContractEvent } from "@wagmi/solid/actions";
import { anvil, hoodi, sepolia } from "@wagmi/solid/chains";
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
type OffersInfiniteData = {
  pages: OffersPage[];
  pageParams: number[];
};
type SupportedChainId = typeof anvil.id | typeof sepolia.id | typeof hoodi.id;
type OfferTuple = readonly [
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
];
type OfferSyncOwner = {
  refCount: number;
  cleanup: () => void;
};
type OfferEventLog = {
  args?: {
    offer_id?: bigint;
  };
};

const PAGE_SIZE = 25n;
const REPLAY_HEALTH_CHECK_INTERVAL = 30_000;
const MAX_REPLAY_BLOCK_WINDOW = 2000n;
const offerSyncOwners = new Map<string, OfferSyncOwner>();

export const decodeOfferTuple = (offer: OfferTuple): Offer => ({
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

export const applyOfferToCaches = (chainId: number, offer: Offer) => {
  queryClient.setQueryData(queryKeys.offers.single(chainId, offer.id), () => offer);
  queryClient.setQueryData(queryKeys.offers.all(chainId), (stale: OffersInfiniteData | undefined) => {
    if (!stale) return stale;

    return {
      ...stale,
      pages: upsertOfferInPages(stale.pages, offer),
    };
  });
};

export const invalidateOfferCaches = async (chainId: number, offerId?: bigint) => {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId) }),
    offerId === undefined
      ? Promise.resolve()
      : queryClient.invalidateQueries({ queryKey: queryKeys.offers.single(chainId, offerId) }),
  ]);
};

const getOfferIdsFromLogs = (logs: OfferEventLog[]) => [...new Set(logs
  .map(log => log.args?.offer_id)
  .filter((offerId): offerId is bigint => offerId !== undefined))];

const repartitionOffers = (pages: OffersPage[], offers: Offer[]): OffersPage[] => {
  let cursor = 0;

  return pages.map((page) => {
    const nextCursor = cursor + page.offers.length;
    const nextPageOffers = offers.slice(cursor, nextCursor);

    cursor = nextCursor;

    return {
      ...page,
      offers: nextPageOffers,
    };
  });
};

const readOffer = async (chainId: SupportedChainId, address: `0x${string}`, offerId: bigint) => {
  const offerRaw = await readContract(config, {
    abi: ABI,
    functionName: "offers",
    args: [offerId],
    address,
    chainId,
  });

  return decodeOfferTuple(offerRaw);
};

const upsertOfferInPages = (pages: OffersPage[], offer: Offer): OffersPage[] => {
  if (pages.length === 0) return pages;

  const loadedOffers = pages.flatMap(page => page.offers);
  const existingIndex = loadedOffers.findIndex(entry => entry.id === offer.id);

  if (existingIndex !== -1) {
    const nextOffers = [...loadedOffers];

    if (offer.state === 0) {
      nextOffers.splice(existingIndex, 1);
    }
    else {
      nextOffers[existingIndex] = offer;
    }

    return repartitionOffers(pages, nextOffers);
  }

  if (offer.state === 0) return pages;

  const newestLoadedId = loadedOffers[0]?.id;

  if (newestLoadedId !== undefined && offer.id <= newestLoadedId) {
    return pages;
  }

  return repartitionOffers(pages, [offer, ...loadedOffers].slice(0, loadedOffers.length));
};

const createOfferSyncOwner = (currentChainId: SupportedChainId, address: `0x${string}`) => {
  let lastSyncedBlock: bigint | undefined;
  let replayRunning = false;
  let syncReady = false;

  const refetchSnapshot = async () => {
    await invalidateOfferCaches(currentChainId);
    lastSyncedBlock = await getBlockNumber(config, { chainId: currentChainId });
  };

  const syncOfferIds = async (offerIds: bigint[]) => {
    if (offerIds.length === 0) return;

    await Promise.all(offerIds.map(async (offerId) => {
      applyOfferToCaches(currentChainId, await readOffer(currentChainId, address, offerId));
    }));
  };

  const replaySinceLastSyncedBlock = async () => {
    if (replayRunning || lastSyncedBlock === undefined || !syncReady) return;

    replayRunning = true;

    try {
      const latestBlock = await getBlockNumber(config, { chainId: currentChainId });

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
        chainId: currentChainId,
        fromBlock,
        toBlock: latestBlock,
      });

      const offerIds = getOfferIdsFromLogs(logs);

      await syncOfferIds(offerIds);
      lastSyncedBlock = latestBlock;
    }
    catch {
      await refetchSnapshot();
    }
    finally {
      replayRunning = false;
    }
  };

  const bootstrapSync = async () => {
    const bootBlock = await getBlockNumber(config, { chainId: currentChainId });

    lastSyncedBlock = bootBlock > 0n ? bootBlock - 1n : 0n;
    syncReady = true;

    await replaySinceLastSyncedBlock();
  };

  const unwatch = watchContractEvent(config, {
    abi: ABI,
    address,
    chainId: currentChainId,
    eventName: "OfferEvent",
    onLogs: (logs) => {
      if (logs.length === 0) return;

      const offerIds = getOfferIdsFromLogs(logs);
      const maxBlockInBatch = logs.reduce<bigint | undefined>((max, log) => {
        if (max === undefined || log.blockNumber > max) return log.blockNumber;

        return max;
      }, lastSyncedBlock);

      void syncOfferIds(offerIds).then(() => {
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

  void bootstrapSync();

  return () => {
    unwatch();
    clearInterval(healthCheck);
  };
};

const retainOfferSyncOwner = (currentChainId: SupportedChainId, address: `0x${string}`) => {
  const key = `${currentChainId}:${address.toLowerCase()}`;
  const existing = offerSyncOwners.get(key);

  if (existing) {
    existing.refCount += 1;
  }
  else {
    offerSyncOwners.set(key, {
      refCount: 1,
      cleanup: createOfferSyncOwner(currentChainId, address),
    });
  }

  return () => {
    const owner = offerSyncOwners.get(key);

    if (!owner) return;

    owner.refCount -= 1;

    if (owner.refCount > 0) return;

    owner.cleanup();
    offerSyncOwners.delete(key);
  };
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

      const pageIndex = BigInt(pageParam);
      const pageEndExclusive = nextOfferId - pageIndex * PAGE_SIZE;

      if (pageEndExclusive <= 1n) {
        return {
          offers: [],
          hasMore: false,
        } satisfies OffersPage;
      }

      const pageStart = pageEndExclusive > PAGE_SIZE ? pageEndExclusive - PAGE_SIZE : 1n;
      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [pageStart, pageEndExclusive - pageStart, false],
        address: contractAddress() as `0x${string}`,
        chainId: chainId()!,
      });

      const pageOffers = offers
        .filter(offer => offer.state !== 0)
        .reverse();

      pageOffers.forEach(offer => applyOfferToCaches(chainId()!, offer));

      return {
        offers: pageOffers,
        hasMore: pageStart > 1n,
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

    if (!currentChainId || !address) return;

    const release = retainOfferSyncOwner(currentChainId, address as `0x${string}`);

    onCleanup(() => {
      release();
    });
  });

  return query;
};
