import { useMutation } from "@tanstack/solid-query";
import { getAccount, simulateContract, writeContract } from "@wagmi/core";
import { english, generateMnemonic } from "viem/accounts";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { storeOrderKeys } from "../utils/keyStore";
import type { Offer } from "../utils/offers";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import { updateOfferInCache } from "./utils/optimisticOffers";

export const useTakeOrder = () => {
  const { chainId, contractAddress } = useApp();

  return useMutation(() => ({
    mutationFn: async (offer: Offer) => {
      const address = contractAddress();

      if (!address) throw new Error("Contract address not configured");

      const account = getAccount(config);

      if (!account.address) throw new Error("Wallet not connected");

      const seedphrase = generateMnemonic(english);
      const keys = generateMoneroKeys(seedphrase);

      const isBuy = offer.kind === 1;
      const spendingKey = keys.publicSpendKey;
      const viewingKey = isBuy ? keys.privateViewKey : keys.publicViewKey;
      const value = isBuy ? offer.deposit : offer.amount;
      const role = isBuy ? "xmr" : "evm";

      const { request } = await simulateContract(config, {
        abi: ABI,
        functionName: "take",
        args: [offer.id, spendingKey, viewingKey], // eslint-disable-line no-restricted-syntax
        address,
        value,
      });

      const hash = await writeContract(config, request);

      storeOrderKeys({
        offer_id: offer.id.toString(), // eslint-disable-line no-restricted-syntax
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
    onMutate: async (offer: Offer) => {
      const key = queryKeys.offers.all(chainId()!);

      await queryClient.cancelQueries({ queryKey: key });
      const previousOffers = queryClient.getQueryData(key);

      updateOfferInCache(key, offer.id, { state: 2 }); // eslint-disable-line no-restricted-syntax

      return { previousOffers };
    },
    onError: (_err: unknown, _offer: Offer, context: { previousOffers: unknown; } | undefined) => {
      if (context?.previousOffers) {
        queryClient.setQueryData(queryKeys.offers.all(chainId()!), context.previousOffers);
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId()!) });
    },
  }));
};
