import { createQuery, useMutation } from "@tanstack/solid-query";
import { getConnection, simulateContract, writeContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { english, generateMnemonic } from "viem/accounts";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { storeOrderKeys } from "../utils/keyStore";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";
import type { Offer } from "./useOffers";

export const useTakeOrder = (offer: Accessor<Offer | undefined>) => {
  const { chainId, contractAddress } = useApp();

  const seedphrase = generateMnemonic(english);
  const keys = generateMoneroKeys(seedphrase);

  const simulationArgs = () => {
    const o = offer();

    if (!o) return undefined;

    const isBuy = o.kind === 1;

    return {
      offerId: o.id, // eslint-disable-line no-restricted-syntax
      spendingKey: keys.publicSpendKey,
      viewingKey: isBuy ? keys.privateViewKey : keys.publicViewKey,
      value: isBuy ? o.deposit : o.amount,
    };
  };

  const simulation = createQuery(() => {
    const args = simulationArgs();

    return {
      queryKey: queryKeys.simulate.take(
        chainId()!,
        args?.offerId ?? 0n,
        keys.publicSpendKey,
        args?.viewingKey ?? 0n,
      ),
      queryFn: () => {
        const a = simulationArgs()!;

        return simulateContract(config, {
          abi: ABI,
          functionName: "take",
          args: [a.offerId, a.spendingKey, a.viewingKey],
          address: contractAddress()!,
          value: a.value,
        });
      },
      enabled: !!args && !!contractAddress(),
    };
  });

  const write = useMutation(() => ({
    mutationFn: async () => {
      if (!simulation.data) throw new Error("Simulation not ready");

      const o = offer();

      if (!o) throw new Error("No offer");

      const account = getConnection(config);

      if (!account.address) throw new Error("Wallet not connected");

      const hash = await writeContract(config, simulation.data.request);

      const isBuy = o.kind === 1;
      const role = isBuy ? "xmr" : "evm";

      storeOrderKeys({
        offer_id: o.id.toString(), // eslint-disable-line no-restricted-syntax
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
      // eslint-disable-next-line no-restricted-syntax
      queryClient.invalidateQueries({ queryKey: queryKeys.offers.single(chainId()!, offer()?.id ?? 0n) });
    },
  }));

  return { simulation, write };
};
