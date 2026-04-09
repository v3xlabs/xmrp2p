import { createQuery, useMutation } from "@tanstack/solid-query";
import { useBlockNumber } from "@wagmi/solid";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import { type Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config, queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { useOffer } from "./useOffer";

export const useCancelOrder = (offerId: Accessor<bigint | undefined>) => {
  const { chainId, contractAddress } = useApp();
  const blockNumber = useBlockNumber();
  const offer = useOffer(offerId() ?? 0n);

  const enabled = () => (
    !!offerId()
    && !!contractAddress()
    && offer.data?.blockTaken
    && !!blockNumber.data
    && (blockNumber.data > (offer.data.blockTaken + 1n))
  ) || false;

  const simulation = createQuery(() => ({
    queryKey: queryKeys.simulate.cancel(chainId()!, offerId() ?? 0n),
    queryFn: () => simulateContract(config, {
      abi: ABI,
      functionName: "cancel",
      args: [offerId()!],
      address: contractAddress()!,
    }),
    enabled: enabled(),
  }));

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      return writeContract(config, simulation.data.request);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.single(chainId()!, offerId() ?? 0n) });
    },
    enabled: enabled(),
  }));

  return { simulation, write };
};
