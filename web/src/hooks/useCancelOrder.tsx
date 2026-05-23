import { createQuery, useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export const useCancelOrder = (offerId: Accessor<bigint | undefined>) => {
  const { chainId, contractAddress } = useApp();

  const simulation = createQuery(() => {
    const _chainId = chainId();
    const _offerId = offerId();
    const _contractAddress = contractAddress();

    return {
      queryKey: queryKeys.simulate.cancel(_chainId!, _offerId ?? 0n),
      queryFn: () => simulateContract(config, {
        abi: ABI,
        functionName: "cancel",
        args: [_offerId!],
        address: _contractAddress!,
        chainId: _chainId!,
      }),
      enabled: !!_chainId && !!_offerId && !!_contractAddress,
    };
  });

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      return writeContract(config, simulation.data.request);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.single(chainId()!, offerId() ?? 0n) });
    },
  }));

  return { simulation, write };
};
