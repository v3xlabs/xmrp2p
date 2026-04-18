import { createQuery } from "@tanstack/solid-query";
import { useConfig } from "@wagmi/solid";
import { readContract } from "@wagmi/solid/actions";
import { ABI } from "xmrp2p";

import { queryKeys } from "../utils/queryKeys";
import { decodeOfferTuple } from "./offerCodec";
import { useApp } from "./useApp";

export const useOffer = (offerId: bigint) => {
  const { chainId, contractAddress } = useApp();
  const config = useConfig();

  return createQuery(() => ({
    queryKey: queryKeys.offers.single(chainId()!, offerId),
    queryFn: async () => {
      const offer = await readContract(config(), {
        abi: ABI,
        functionName: "offers",
        args: [offerId],
        address: contractAddress()!,
        chainId: chainId()!,
      });

      return decodeOfferTuple(offer);
    },
  }));
};
