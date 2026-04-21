import { createInfiniteQuery } from "@tanstack/solid-query";
import { readContract } from "@wagmi/solid/actions";
import { createEffect, onCleanup } from "solid-js";
import { ABI } from "xmrp2p";

import { config } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { applyOfferToCaches, type OffersPage } from "./offerCache";
import { retainOfferSyncOwner, type SupportedChainId } from "./offerSync";
import { useApp } from "./useApp";

export { invalidateOfferCaches } from "./offerCache";
export type { Offer } from "./offerCodec";

const PAGE_SIZE = 25n;

const getOffersPage = async (
  chainId: SupportedChainId,
  address: `0x${string}`,
  pageIndex: bigint,
): Promise<OffersPage> => {
  const nextOfferId = await readContract(config, {
    abi: ABI,
    functionName: "nextOfferId",
    address,
    chainId,
  });

  const pageEndExclusive = nextOfferId - pageIndex * PAGE_SIZE;

  if (pageEndExclusive <= 1n) {
    return {
      offers: [],
      hasMore: false,
    };
  }

  const pageStart = pageEndExclusive > PAGE_SIZE ? pageEndExclusive - PAGE_SIZE : 1n;
  const offers = await readContract(config, {
    abi: ABI,
    functionName: "listOffers",
    args: [pageStart, pageEndExclusive - pageStart, false],
    address,
    chainId,
  });

  const pageOffers = offers
    .filter(offer => offer.state !== 0)
    .reverse();

  pageOffers.forEach(offer => applyOfferToCaches(chainId, offer));

  return {
    offers: pageOffers,
    hasMore: pageStart > 1n,
  };
};

export const useOffers = () => {
  const { chainId, contractAddress } = useApp();

  const query = createInfiniteQuery(() => ({
    queryKey: queryKeys.offers.all(chainId()!),
    queryFn: ({ pageParam }) => getOffersPage(
      chainId()! as SupportedChainId,
      contractAddress() as `0x${string}`,
      BigInt(pageParam),
    ),
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
