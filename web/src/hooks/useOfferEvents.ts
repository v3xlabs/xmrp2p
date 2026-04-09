import { createQuery } from "@tanstack/solid-query";
import { getBlock, getContractEvents } from "@wagmi/solid/actions";
import type { Accessor } from "solid-js";
import { ABI } from "xmrp2p";

import { config } from "../config";
import { queryKeys } from "../utils/queryKeys";
import { useApp } from "./useApp";

export type OfferEvent = {
  offer_id: bigint;
  state: number;
  blockNumber: bigint;
  timestamp: bigint;
  transactionHash: string;
};

export const useOfferEvents = (
  offerId: Accessor<bigint | undefined>,
  lastupdate: Accessor<bigint | undefined>,
) => {
  const { chainId, contractAddress } = useApp();

  return createQuery(() => ({
    queryKey: queryKeys.offerEvents(chainId()!, offerId() ?? 0n, lastupdate() ?? 0n),
    queryFn: async (): Promise<OfferEvent[]> => {
      const address = contractAddress();
      const offerIdValue = offerId();

      if (!address || offerIdValue === undefined) return [];

      const logs = await getContractEvents(config, {
        abi: ABI,
        eventName: "OfferEvent",
        address,
        fromBlock: 0n,
      });

      const filtered = logs
        .filter(log => log.args.offer_id === offerIdValue)
        .sort((a, b) => Number(a.blockNumber - b.blockNumber));

      const uniqueBlocks = [...new Set(filtered.map(e => e.blockNumber))];
      const blocks = await Promise.all(
        uniqueBlocks.map(blockNumber => getBlock(config, { blockNumber })),
      );
      const timestampByBlock = new Map(blocks.map(b => [b.number, b.timestamp]));

      return filtered.map(log => ({
        offer_id: log.args.offer_id!,
        state: log.args.state!,
        blockNumber: log.blockNumber,
        timestamp: timestampByBlock.get(log.blockNumber) ?? 0n,
        transactionHash: log.transactionHash,
      }));
    },
    enabled: !!offerId() && !!contractAddress(),
  }));
};
