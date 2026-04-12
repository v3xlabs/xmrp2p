import { createInfiniteQuery } from "@tanstack/solid-query";
import { readContract, watchContractEvent } from "@wagmi/solid/actions";
import { anvil, sepolia } from "@wagmi/solid/chains";
import { type Accessor, createEffect, onCleanup } from "solid-js";
import { ABI, getOffers } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];
type SupportedChainId = typeof anvil.id | typeof sepolia.id;

const PAGE_SIZE = 10n;

const POLL_INTERVAL_DEFAULT = 50_000;
const POLL_INTERVAL_ACTIVE = 10_000;
const EVENT_POLL_INTERVAL = 4_000;

export const useOffers = (activeOfferId?: Accessor<bigint | null>) => {
  const { chainId, contractAddress } = useApp();

  const query = createInfiniteQuery(() => ({
    queryKey: queryKeys.offers.all(chainId()!),
    queryFn: async ({ pageParam }) => {
      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [BigInt(pageParam) * PAGE_SIZE, PAGE_SIZE + 1n, false],
        address: contractAddress() as `0x${string}`,
        chainId: chainId()!,
      });

      const offersFiltered = offers.filter(offer => offer.state !== 0);

      for (const offer of offersFiltered) {
        // eslint-disable-next-line no-restricted-syntax
        const stale = queryClient.getQueryData(queryKeys.offers.single(chainId()!, offer.id));

        if (JSON.stringify(stale) === JSON.stringify(offer)) {
          continue;
        }

        // eslint-disable-next-line no-restricted-syntax
        queryClient.setQueryData(queryKeys.offers.single(chainId()!, offer.id), () => offer);
      }

      return offersFiltered;
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => (lastPage.length >= 10 ? pages.length : undefined),
    refetchInterval: activeOfferId?.() ? POLL_INTERVAL_ACTIVE : POLL_INTERVAL_DEFAULT,
  }));

  createEffect(() => {
    const currentChainId = chainId() as SupportedChainId | undefined;
    const address = contractAddress();

    if (!currentChainId || !address) return;

    const unwatch = watchContractEvent(config, {
      abi: ABI,
      address,
      chainId: currentChainId,
      eventName: "OfferEvent",
      poll: true,
      pollingInterval: EVENT_POLL_INTERVAL,
      onLogs: (logs) => {
        if (logs.length === 0) return;

        void query.refetch();
      },
    });

    onCleanup(() => {
      unwatch();
    });
  });

  return query;
};
