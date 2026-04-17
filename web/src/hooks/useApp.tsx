/* eslint-disable no-restricted-syntax */
import { useChainId, useChains } from "@wagmi/solid";
import { createMemo } from "solid-js";
import { anvil, hoodi, mainnet, sepolia } from "viem/chains";

import { config, CONTRACT_ADDRESS } from "../config";
import { useSettings } from "../context/SettingsContext";
import { useParameters } from "./useParameters";

export const useApp = () => {
  const { modes, ...settings } = useSettings();

  type AppChainId = (typeof config)["chains"][number]["id"];

  const wagmiChains = useChains();
  const chains = createMemo(() => wagmiChains().filter((chain) => {
    if (modes.devnets && chain.id === anvil.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    if (modes.testnets && chain.id === sepolia.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    if (modes.testnets && chain.id === hoodi.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    if (modes.mainnets && chain.id === mainnet.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    return false;
  }));

  const chainIdWagmi = useChainId();
  const chainId = createMemo<AppChainId | undefined>(() => {
    const chainId2 = chainIdWagmi() as AppChainId;
    const fallbackChainId = chains()[0]?.id as AppChainId | undefined;

    if (!chains().some(chain => chain.id === chainId2)) {
      return fallbackChainId ?? chainId2;
    }

    return chainId2;
  });
  const contractAddress = () => CONTRACT_ADDRESS[chainId()!] as `0x${string}` | undefined;
  const parameters = useParameters(chainId, contractAddress);

  return {
    chainId,
    contractAddress,
    parameters,
    chains,
    settings: { ...settings, modes },
  };
};
