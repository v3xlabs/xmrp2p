import { createInfiniteQuery } from "@tanstack/solid-query";
import { useChainId } from "@wagmi/solid";
import { readContract } from "@wagmi/solid/actions";
import { ABI, getOffers } from "xmrp2p";

import { config, CONTRACT_ADDRESS } from "../config";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];

const PAGE_SIZE = 10n;

export const useOffers = () => {
  const chainId = useChainId();

  return createInfiniteQuery(() => ({
    queryKey: ["offers"],
    queryFn: async ({ pageParam }) => {
      const contractAddress = CONTRACT_ADDRESS[chainId()!] as `0x${string}`;

      console.log({ pageParam });

      const offers = await readContract(config, {
        abi: ABI,
        functionName: "listOffers",
        args: [BigInt(pageParam) * PAGE_SIZE, PAGE_SIZE + 1n, true],
        address: contractAddress,
        chainId: chainId()!,
      });

      console.log({ offers });

      return offers.filter(offer => offer.state !== 0);
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => (lastPage.length >= 10 ? pages.length : undefined),
  }));
};
