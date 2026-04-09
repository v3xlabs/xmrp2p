import { useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { updateOfferInCache } from "./utils/optimisticOffers";

export const useClaimOrder = () => {
  const { chainId, contractAddress } = useApp();

  return useMutation(() => ({
    mutationFn: async (params: { offer_id: bigint; privateSpendKey: bigint; }) => {
      const address = contractAddress();

      if (!address) throw new Error("Contract address not configured");

      const { request } = await simulateContract(config, {
        abi: ABI,
        functionName: "claim",
        args: [params.offer_id, params.privateSpendKey],
        address,
      });

      return writeContract(config, request);
    },
    onMutate: async (params: { offer_id: bigint; privateSpendKey: bigint; }) => {
      const key = queryKeys.offers.all(chainId()!);

      await queryClient.cancelQueries({ queryKey: key });
      const previousOffers = queryClient.getQueryData(key);

      updateOfferInCache(key, params.offer_id, { state: 6 });

      return { previousOffers };
    },
    onError: (_err: unknown, _params: unknown, context: { previousOffers: unknown; } | undefined) => {
      if (context?.previousOffers) {
        queryClient.setQueryData(queryKeys.offers.all(chainId()!), context.previousOffers);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
    },
  }));
};
