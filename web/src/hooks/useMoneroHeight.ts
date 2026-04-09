import { createQuery } from "@tanstack/solid-query";
import type { Accessor } from "solid-js";

import { queryKeys } from "../utils/queryKeys";

const MONERO_RPC = "https://xmr-node.cakewallet.com:18081/json_rpc";

const MONERO_GENESIS_TIMESTAMP = 1_397_818_193;
const V2_FORK_HEIGHT = 1_009_827;
const V2_FORK_TIMESTAMP = 1_458_748_658;
const BLOCK_TIME = 120;

const roughEstimate = (targetTimestamp: number): number => {
  if (targetTimestamp <= MONERO_GENESIS_TIMESTAMP) return 0;

  if (targetTimestamp < V2_FORK_TIMESTAMP) {
    return Math.floor((targetTimestamp - MONERO_GENESIS_TIMESTAMP) / 60);
  }

  return V2_FORK_HEIGHT
    + Math.floor((targetTimestamp - V2_FORK_TIMESTAMP) / BLOCK_TIME);
};

const fetchBlockTimestamp = async (height: number): Promise<number> => {
  const res = await fetch(MONERO_RPC, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "get_block_header_by_height",
      params: { height },
    }),
  });

  const json = await res.json();

  return json.result.block_header.timestamp as number;
};

const fetchCurrentHeight = async (): Promise<number> => {
  const res = await fetch(MONERO_RPC, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "get_last_block_header",
    }),
  });

  const json = await res.json();

  return json.result.block_header.height as number;
};

const findMoneroHeight = async (targetTimestamp: number): Promise<number> => {
  const currentHeight = await fetchCurrentHeight();
  let low = 0;
  let high = currentHeight;
  let guess = Math.min(roughEstimate(targetTimestamp), currentHeight);

  while (true) {
    guess = Math.max(low, Math.min(guess, high));
    const ts = await fetchBlockTimestamp(guess);
    const diff = ts - targetTimestamp;

    if (Math.abs(diff) <= BLOCK_TIME) {
      return diff > 0 ? Math.max(0, guess - 1) : guess;
    }

    if (diff > 0) {
      high = guess - 1;
    }
    else {
      low = guess + 1;
    }

    if (low > high) {
      return Math.max(0, Math.min(low, high));
    }

    const stepBlocks = Math.max(1, Math.floor(Math.abs(diff) / BLOCK_TIME));

    guess = diff > 0 ? guess - stepBlocks : guess + stepBlocks;
  }
};

export const useMoneroHeight = (timestamp: Accessor<number | undefined>) =>
  createQuery(() => ({
    queryKey: queryKeys.moneroHeight(timestamp()),
    queryFn: () => findMoneroHeight(timestamp()!),
    enabled: !!timestamp() && timestamp()! > 0,
    staleTime: Number.POSITIVE_INFINITY,
  }));
