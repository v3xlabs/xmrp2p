import { createQuery } from "@tanstack/solid-query";
import { getBlock } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";

import { config } from "../config";
import { queryKeys } from "../utils/queryKeys";

export const useBlockTimestamp = (blockNumber: Accessor<bigint | undefined>) =>
  createQuery(() => ({
    queryKey: queryKeys.blockTimestamp(blockNumber()?.toString()),
    queryFn: async () => {
      const block = await getBlock(config, { blockNumber: blockNumber()! });

      return Number(block.timestamp);
    },
    enabled: !!blockNumber() && blockNumber()! > 0n,
    staleTime: Number.POSITIVE_INFINITY,
  }));
