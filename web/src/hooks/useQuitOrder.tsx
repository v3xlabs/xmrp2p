import { createQuery, useMutation } from "@tanstack/solid-query";
import { useBlockNumber } from "@wagmi/solid";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { useOffer } from "./useOffer";
import { invalidateOfferCaches } from "./useOffers";

export type QuitParams = {
  offer_id: bigint;
  privateSpendKey: bigint;
  privateViewKey: bigint;
};

export const useQuitOrder = (params: Accessor<QuitParams | undefined>) => {
  const { chainId, contractAddress } = useApp();
  const offer = useOffer(params()?.offer_id ?? 0n);

  const blockNumber = useBlockNumber();

  const simulation = createQuery(() => {
    const p = params();
    const address = contractAddress();

    const enabled = (
      !!p && !!address && p.privateSpendKey !== 0n && p.privateViewKey !== 0n
      && !!blockNumber.data && !!offer.data?.blockTaken && (blockNumber.data > (offer.data.blockTaken ?? 0n + 1n))
    ) || false;

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
      enabled,
    };
  });

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      if ("error" in simulation.data) throw new Error("Simulation failed");

      return writeContract(config, simulation.data.request);
    },
    onSettled: () => {
      void invalidateOfferCaches(chainId()!, params()?.offer_id);
    },
  }));

  return { simulation, write };
};
