import { createQuery } from "@tanstack/solid-query";

import { queryKeys } from "../queryKeys";
import { fetchETHPrice } from "./fetchETHPrice";
import { fetchXMRPrice } from "./fetchXMRPrice";

export const useMarketRate = () =>
  createQuery(() => ({
    queryKey: queryKeys.marketRate(),
    queryFn: async () => {
      const [ethUsd, xmrUsd] = await Promise.all([
        fetchETHPrice(),
        fetchXMRPrice(),
      ]);

      return {
        ethUsd,
        xmrUsd,
        xmrPerEth: ethUsd / xmrUsd,
      };
    },
    refetchInterval: 60_000,
    staleTime: 30_000,
  }));
