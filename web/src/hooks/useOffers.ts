/* eslint-disable no-restricted-syntax */
import { createInfiniteQuery } from "@tanstack/solid-query";
import { readContract, watchContractEvent } from "@wagmi/solid/actions";
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
      onLogs: (logs) => {
        if (logs.length === 0) return;

        for (const log of logs) {
          if (log.args.offer_id !== undefined) {
            void queryClient.invalidateQueries({
              queryKey: queryKeys.offers.single(currentChainId, log.args.offer_id),
            });
          }
        }

        void query.refetch();
      },
    });

    onCleanup(() => {
      unwatch();
    });
  });

  return query;
};
