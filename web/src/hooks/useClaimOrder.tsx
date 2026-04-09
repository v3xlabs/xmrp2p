import { createQuery, useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type ClaimParams = {
  offer_id: bigint;
  privateSpendKey: bigint;
};

export const useClaimOrder = (params: Accessor<ClaimParams | undefined>) => {
  const { chainId, contractAddress } = useApp();

  const simulation = createQuery(() => ({
    queryKey: queryKeys.simulate.claim(
      chainId()!,
      params()?.offer_id ?? 0n,
      params()?.privateSpendKey ?? 0n,
    ),
    queryFn: () => {
      const p = params()!;

      return simulateContract(config, {
        abi: ABI,
        functionName: "claim",
        args: [p.offer_id, p.privateSpendKey],
        address: contractAddress()!,
      });
    },
    enabled: !!params() && !!contractAddress(),
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
