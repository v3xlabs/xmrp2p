import { useChainId } from "@wagmi/solid";

import { config, CONTRACT_ADDRESS } from "../config";
import { useParameters } from "./useParameters";

export const useApp = () => {
  const chainIdWagmi = useChainId();
  const chainId = () => chainIdWagmi() as (typeof config)["chains"][number]["id"];

  const contractAddress = () => CONTRACT_ADDRESS[chainId()!] as `0x${string}` | undefined;

  const parameters = useParameters(chainId, contractAddress);

  return {
    chainId,
    contractAddress,
    parameters,
  };
};
