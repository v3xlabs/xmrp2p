import { createInfiniteQuery } from "@tanstack/solid-query";
import { readContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI, getOffers } from "xmrp2p";

import { config } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];

const PAGE_SIZE = 10n;

const POLL_INTERVAL_DEFAULT = 50_000;
const POLL_INTERVAL_ACTIVE = 10_000;

export const useOffers = (activeOfferId?: Accessor<bigint | null>) => {
  const { chainId, contractAddress } = useApp();

  return createInfiniteQuery(() => ({
    queryKey: queryKeys.offers.all(chainId()!),
    queryFn: async ({ pageParam }) => {
      console.log("chainId", chainId()!);
      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [BigInt(pageParam) * PAGE_SIZE, PAGE_SIZE + 1n, false],
        address: contractAddress() as `0x${string}`,
        chainId: chainId()!,
      });

      console.log("offers", offers);

      return offers.filter(offer => offer.state !== 0);
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => (lastPage.length >= 10 ? pages.length : undefined),
    refetchInterval: activeOfferId?.() ? POLL_INTERVAL_ACTIVE : POLL_INTERVAL_DEFAULT,
  }));
};
