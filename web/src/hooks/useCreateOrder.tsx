import { useMutation, useQuery } from "@tanstack/solid-query";
import { getAccount, simulateContract, writeContract } from "@wagmi/solid/actions";
import { english, generateMnemonic } from "viem/accounts";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { storeOrderKeys } from "../utils/keyStore";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { useSwap } from "./useSwap";

export const useCreateOrder = () => {
  const { chainId, contractAddress } = useApp();
  const { offerType, rateValue, ethAmount, ...swap } = useSwap();

  const seedphrase = generateMnemonic(english);
  const keys = generateMoneroKeys(seedphrase);

  const prepareOrder = useQuery(() => ({
    queryKey: queryKeys.prepareOrder(chainId()!, offerType(), rateValue() ?? 0n, ethAmount()),
    queryFn: async () => {
      const address = contractAddress();
      const value = ethAmount();
      const rateValuex = rateValue();

      if (!address || !rateValuex) return null;

      const type = offerType();
      const viewKey = type === 1 ? keys.publicViewKey : keys.privateViewKey;

      const data = await simulateContract(config, {
        abi: ABI,
        functionName: "offer",
        args: [
          type,
          rateValuex,
          "0x0000000000000000000000000000000000000000",
          keys.publicSpendKey,
          viewKey,
        ],
        address,
        value,
      });

      return data;
    },
  }));

  const createOffer = useMutation(() => ({
    mutationFn: async () => {
      if (!prepareOrder.data) return;

      const hash = await writeContract(config, prepareOrder.data.request);

      const account = getAccount(config);

      if (!account.address) throw new Error("Wallet not connected");

      const simulatedOffer = prepareOrder.data.result;
      const offerId = simulatedOffer.id; // eslint-disable-line no-restricted-syntax
      const type = offerType();
      const role = type === 1 ? "evm" : "xmr";

      storeOrderKeys({
        offer_id: offerId.toString(),
        chain_id: chainId()!,
        wallet_address: account.address,
        role: role as "evm" | "xmr",
        mnemonic: seedphrase,
        privateSpendKey: keys.privateSpendKey.toString(),
        privateViewKey: keys.privateViewKey.toString(),
        publicSpendKey: keys.publicSpendKey.toString(),
        publicViewKey: keys.publicViewKey.toString(),
      });

      return hash;
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
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
