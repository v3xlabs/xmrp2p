import { createQuery } from "@tanstack/solid-query";
import { readContract } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import type { Address } from "viem";

import { ABI } from "../../../lib/src/abi";
import { config } from "../config";

export const useParameters = (
  chainId: Accessor<number | undefined>,
  contractAddress: Accessor<Address | undefined>,
) => createQuery(() => ({
  queryKey: ["c", chainId(), "parameters"],
  queryFn: async () => {
    const address = contractAddress();

    if (!address) return null;

    const parameters = await readContract(config, {
      abi: ABI,
      functionName: "parameters",
      address,
    });

    return parameters;
  },
}));
