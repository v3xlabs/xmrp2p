import { useMutation, useQuery } from "@tanstack/solid-query";
import { simulateContract, writeContract } from "@wagmi/solid/actions";
import { english, generateMnemonic } from "viem/accounts";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { useApp } from "./useApp";
import { useSwap } from "./useSwap";

export const useCreateOrder = () => {
  const { chainId, contractAddress } = useApp();
  const { offerType, rateValue, ethAmount, ...swap } = useSwap();

  const seedphrase = generateMnemonic(english);
  const { publicSpendKey, publicViewKey } = generateMoneroKeys(seedphrase);

  const prepareOrder = useQuery(() => ({
    queryKey: ["c", chainId(), "prepareOrder", offerType(), rateValue(), ethAmount()],
    queryFn: async () => {
      const address = contractAddress();
      const value = ethAmount();
      const rateValuex = rateValue();

      if (!address || !rateValuex) return null;

      console.log("simulating");

      const data = await simulateContract(config, {
        abi: ABI,
        functionName: "offer",
        args: [
          offerType(),
          rateValuex,
          "0x0000000000000000000000000000000000000000",
          publicSpendKey,
          publicViewKey,
        ],
        address,
        value,
      });

      console.log({ data });

      return data;
    },
  }));
  const createOffer = useMutation(() => ({
    mutationFn: async () => {
      console.log({ ethAmount: ethAmount(), offerType: offerType(), rateValue });

      if (!prepareOrder.data) return;

      const hash = await writeContract(config, prepareOrder.data.request);

      console.log({ hash });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["offers"] });
    },
  }));

  return {
    prepareOrder,
    createOffer,
    offerType,
    rateValue,
    ethAmount,
    swap,
  };
};
