import { createQuery } from "@tanstack/solid-query";
import { useConfig } from "@wagmi/solid";
import { readContract } from "@wagmi/solid/actions";
import { ABI } from "xmrp2p";

import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import type { Offer } from "./useOffers";

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

      const decoded: Offer = {
        // eslint-disable-next-line no-restricted-syntax
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
      };

      return decoded;
    },
  }));
};
