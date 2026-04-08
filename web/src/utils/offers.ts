import { createInfiniteQuery } from "@tanstack/solid-query";
import { readContract } from "@wagmi/solid/actions";
import { ABI, getOffers } from "xmrp2p";

import { config } from "../config";
import { useApp } from "../hooks/useApp";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];

const PAGE_SIZE = 10n;

export const useOffers = () => {
  const { chainId, contractAddress } = useApp();

  return createInfiniteQuery(() => ({
    queryKey: ["c", chainId(), "offers"],
    queryFn: async ({ pageParam }) => {
      console.log({ pageParam });

      // await new Promise(resolve => setTimeout(resolve, 2000));

      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [BigInt(pageParam) * PAGE_SIZE, PAGE_SIZE + 1n, true],
        address: contractAddress(),
        chainId: chainId(),
      });

      console.log({ offers });

      return offers.filter(offer => offer.state !== 0);
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => (lastPage.length >= 10 ? pages.length : undefined),
    refetchInterval: 5000,
  }));
};
