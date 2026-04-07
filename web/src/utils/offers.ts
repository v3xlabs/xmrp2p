import { createQuery } from "@tanstack/solid-query";
import { useChainId, useClient } from "@wagmi/solid";
import { type Client, publicActions } from "viem";
import { getOffers } from "xmrp2p";

import { CONTRACT_ADDRESS } from "../config";

export type Offer = Awaited<ReturnType<typeof getOffers>>;

export const useBuyOffers = () => {
  const client = useClient();
  const xx = publicActions(client() as Client);
  const chainId = useChainId();

  return createQuery(() => ({
    queryKey: ["orders", "buy"],
    queryFn: async () => {
      const contractAddress = CONTRACT_ADDRESS[chainId()!] as `0x${string}`;

      const offers = await getOffers(xx);

      console.log({ offers });

      // return await listBuyOffers({
      //   provider,
      //   contractAddress,
      //   offset: BigInt(0),
      //   count: BigInt(10),
      // });
      return [];
    },
    // enabled: !!chainId() && !!client() && !!CONTRACT_ADDRESS[chainId()!],
  }));
};
