import { createQuery } from "@tanstack/solid-query";
import { useChainId, useClient } from "@wagmi/solid";
import type { Provider as OxProvider } from "ox/Provider";
import { listBuyOffers } from "xmrp2p";

import { CONTRACT_ADDRESS } from "../config";

export type Offer = Awaited<ReturnType<typeof listBuyOffers>>[number];

export const useBuyOffers = () => {
  const client = useClient();
  const chainId = useChainId();
  const provider = client() as OxProvider;

  return createQuery(() => ({
    queryKey: ["orders", "buy"],
    queryFn: async () => {
      const contractAddress = CONTRACT_ADDRESS[chainId()!] as `0x${string}`;

      return await listBuyOffers({
        provider,
        contractAddress,
        offset: BigInt(0),
        count: BigInt(10),
      });
    },
    // enabled: !!chainId() && !!client() && !!CONTRACT_ADDRESS[chainId()!],
  }));
};
