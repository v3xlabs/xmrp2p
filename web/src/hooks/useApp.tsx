/* eslint-disable no-restricted-syntax */
import { useChainId, useChains } from "@wagmi/solid";
import { createMemo } from "solid-js";
import { anvil, mainnet, sepolia } from "viem/chains";

import { config, CONTRACT_ADDRESS } from "../config";
import { useSettings } from "../context/SettingsContext";
import { useParameters } from "./useParameters";

export const useApp = () => {
  const chainIdWagmi = useChainId();
  const chainId = createMemo(() => chainIdWagmi() as (typeof config)["chains"][number]["id"]);
  const { modes, ...settings } = useSettings();
  const wagmiChains = useChains();

  const contractAddress = () => CONTRACT_ADDRESS[chainId()!] as `0x${string}` | undefined;

  const parameters = useParameters(chainId, contractAddress);

  const chains = createMemo(() => wagmiChains().filter((chain) => {
    if (modes.devnets && chain.id === anvil.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    if (modes.testnets && chain.id === sepolia.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    if (modes.mainnets && chain.id === mainnet.id && CONTRACT_ADDRESS[chain.id] !== undefined) return true;

    return false;
  }));

  return {
    chainId,
    contractAddress,
    parameters,
    chains,
    settings: { ...settings, modes },
  };
};
