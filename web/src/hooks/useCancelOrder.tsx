import { useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { updateOfferInCache } from "./utils/optimisticOffers";

export const useCancelOrder = () => {
  const { chainId, contractAddress } = useApp();

  return useMutation(() => ({
    mutationFn: async (offerId: bigint) => {
      const address = contractAddress();

      if (!address) throw new Error("Contract address not configured");

      const { request } = await simulateContract(config, {
        abi: ABI,
        functionName: "cancel",
        args: [offerId],
        address,
      });

      return writeContract(config, request);
    },
    onMutate: async (offerId: bigint) => {
      const key = queryKeys.offers.all(chainId()!);

      await queryClient.cancelQueries({ queryKey: key });
      const previousOffers = queryClient.getQueryData(key);

      updateOfferInCache(key, offerId, { state: 3 });

      return { previousOffers };
    },
    onError: (_err: unknown, _offerId: bigint, context: { previousOffers: unknown; } | undefined) => {
      if (context?.previousOffers) {
        queryClient.setQueryData(queryKeys.offers.all(chainId()!), context.previousOffers);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
    },
  }));
};
