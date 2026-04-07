import { createQuery } from "@tanstack/solid-query";

import { fetchETHPrice } from "./fetchETHPrice";
import { fetchXMRPrice } from "./fetchXMRPrice";

export const useMarketRate = () =>
  createQuery(() => ({
    queryKey: ["market-rate", "xmr-eth"],
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
