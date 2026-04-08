import { useChainId } from "@wagmi/solid";

import { CONTRACT_ADDRESS } from "../config";
import { useParameters } from "./useParameters";

export const useApp = () => {
  const chainId = useChainId();

  const contractAddress = () => CONTRACT_ADDRESS[chainId()!] as `0x${string}` | undefined;

  const parameters = useParameters(chainId, contractAddress);

  return {
    chainId,
    contractAddress,
    parameters,
  };
};
