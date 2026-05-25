import { useMutation, useQuery } from "@tanstack/solid-query";
import { getAccount, simulateContract, writeContract } from "@wagmi/solid/actions";
import { createMemo, createSignal } from "solid-js";
import { keccak256, stringToBytes } from "viem";
import { english, generateMnemonic } from "viem/accounts";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { storeOrderKeys } from "../utils/keyStore";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { useSwap } from "./useSwap";

const useCreateKeys = () => {
  const [seedphrase, setSeedphrase] = createSignal(generateMnemonic(english));
  const generate = () => {
    setSeedphrase(generateMnemonic(english));
  };

  const keys = createMemo(() => generateMoneroKeys(seedphrase()));
  const seedHash = createMemo(() => keccak256(stringToBytes(JSON.stringify(keys()))));

  return { seedphrase, keys, generate, seedHash };
};

export const useCreateOrder = () => {
  const { chainId, contractAddress } = useApp();
  const { offerType, xmrAmount, ethAmount, ...swap } = useSwap();
  const { seedphrase, keys, generate, seedHash } = useCreateKeys();

  const prepareOrder = useQuery(() => ({
    queryKey: queryKeys.prepareOrder(chainId()!, offerType(), xmrAmount() ?? 0n, ethAmount(), seedHash()),
    queryFn: async () => {
      const address = contractAddress();
      const value = ethAmount();
      const xmrAmountValue = xmrAmount();
      const k = keys();

      if (!address || !xmrAmountValue) return null;

      const type = offerType();
      const viewKey = type === 1 ? k.publicViewKey : k.privateViewKey;

      const data = await simulateContract(config, {
        abi: ABI,
        functionName: "openOffer",
        args: [
          type,
          xmrAmountValue,
          "0x0000000000000000000000000000000000000000",
          k.publicSpendKey,
          viewKey,
        ],
        address,
        value,
        chainId: chainId()!,
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
      // @ts-expect-error - simulatedOffer is not typed
      // eslint-disable-next-line no-restricted-syntax
      const offerId = simulatedOffer.id;
      const type = offerType();
      const role = type === 1 ? "evm" : "xmr";

      storeOrderKeys({
        offer_id: offerId.toString(),
        chain_id: chainId()!,
        wallet_address: account.address,
        role: role as "evm" | "xmr",
        mnemonic: seedphrase(),
        privateSpendKey: keys().privateSpendKey.toString(),
        privateViewKey: keys().privateViewKey.toString(),
        publicSpendKey: keys().publicSpendKey.toString(),
        publicViewKey: keys().publicViewKey.toString(),
      });

      // Generate new keys
      generate();

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
    xmrAmount,
    ethAmount,
    swap,
  };
};
