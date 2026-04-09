import { createQuery, useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export const useReadyOrder = (offerId: Accessor<bigint | undefined>) => {
  const { chainId, contractAddress } = useApp();

  const simulation = createQuery(() => ({
    queryKey: queryKeys.simulate.ready(chainId()!, offerId() ?? 0n),
    queryFn: () => simulateContract(config, {
      abi: ABI,
      functionName: "ready",
      args: [offerId()!],
      address: contractAddress()!,
    }),
    enabled: !!offerId() && !!contractAddress(),
  }));

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      return writeContract(config, simulation.data.request);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
    },
  }));

  return { simulation, write };
};
