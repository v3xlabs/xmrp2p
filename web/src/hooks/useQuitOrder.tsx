import { createQuery, useMutation } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type QuitParams = {
  offer_id: bigint;
  privateSpendKey: bigint;
  privateViewKey: bigint;
};

export const useQuitOrder = (params: Accessor<QuitParams | undefined>) => {
  const { chainId, contractAddress } = useApp();

  const simulation = createQuery(() => {
    const p = params();
    const address = contractAddress();

    return {
      queryKey: queryKeys.simulate.quit(
        chainId()!,
        p?.offer_id ?? 0n,
        p?.privateSpendKey ?? 0n,
        p?.privateViewKey ?? 0n,
      ),
      queryFn: async () => {
        if (!p?.offer_id || !p?.privateSpendKey || !p?.privateViewKey || !address) return undefined;

        console.log("simulating quit", {
          offer_id: p.offer_id,
          privateSpendKey: p.privateSpendKey,
          privateViewKey: p.privateViewKey,
          address,
        });

        try {
          const data = await simulateContract(config, {
            abi: ABI,
            functionName: "quit",
            args: [p.offer_id, p.privateSpendKey, p.privateViewKey],
            address,
          });

          console.log("simulation result", data);

          return data;
        }
        catch (error) {
          console.error("error simulating quit", error);

          return { error: error as Error };
        }
      },
      enabled: !!p && !!address && p.privateSpendKey !== 0n && p.privateViewKey !== 0n,
    };
  });

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      if ("error" in simulation.data) throw new Error("Simulation failed");

      return writeContract(config, simulation.data.request);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
    },
  }));

  return { simulation, write };
};
