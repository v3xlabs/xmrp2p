/* eslint-disable no-restricted-syntax */
import { getBlockNumber, getContractEvents, readContract, watchContractEvent } from "@wagmi/solid/actions";
import { anvil, hoodi, sepolia } from "@wagmi/solid/chains";
import { ABI } from "xmrp2p";

import { config } from "../config";
import { applyOfferToCaches, invalidateOfferCaches } from "./offerCache";
import { decodeOfferTuple } from "./offerCodec";

export type SupportedChainId = typeof anvil.id | typeof sepolia.id | typeof hoodi.id;

type OfferSyncOwner = {
  refCount: number;
  cleanup: () => void;
};

type OfferEventLog = {
  args?: {
    offer_id?: bigint;
  };
  blockNumber: bigint;
};

type OfferSyncState = {
  lastSyncedBlock: bigint | undefined;
  replayRunning: boolean;
  syncReady: boolean;
};

const REPLAY_HEALTH_CHECK_INTERVAL = 30_000;
const MAX_REPLAY_BLOCK_WINDOW = 2000n;
const offerSyncOwners = new Map<string, OfferSyncOwner>();

const getOfferIdsFromLogs = (logs: OfferEventLog[]) => [...new Set(logs
  .map(log => log.args?.offer_id)
  .filter((offerId): offerId is bigint => offerId !== undefined))];

const getMaxBlockInBatch = (
  logs: OfferEventLog[],
  fallback: bigint | undefined,
) => logs.reduce<bigint | undefined>((max, log) => {
  if (max === undefined || log.blockNumber > max) return log.blockNumber;

  return max;
}, fallback);

const readOffer = async (
  chainId: SupportedChainId,
  address: `0x${string}`,
  offerId: bigint,
) => {
  const offerRaw = await readContract(config, {
    abi: ABI,
    functionName: "offers",
    args: [offerId],
    address,
    chainId,
  });

  return decodeOfferTuple(offerRaw);
};

const syncOfferIds = async (
  chainId: SupportedChainId,
  address: `0x${string}`,
  offerIds: bigint[],
) => {
  if (offerIds.length === 0) return;

  const offers = await Promise.all(offerIds.map(offerId => readOffer(chainId, address, offerId)));

  offers.forEach(offer => applyOfferToCaches(chainId, offer));
};

const createOfferSyncOwner = (currentChainId: SupportedChainId, address: `0x${string}`) => {
  const state: OfferSyncState = {
    lastSyncedBlock: undefined,
    replayRunning: false,
    syncReady: false,
  };

  const refetchSnapshot = async () => {
    await invalidateOfferCaches(currentChainId);
    state.lastSyncedBlock = await getBlockNumber(config, { chainId: currentChainId });
  };

  const replaySinceLastSyncedBlock = async () => {
    if (state.replayRunning || state.lastSyncedBlock === undefined || !state.syncReady) return;

    state.replayRunning = true;

    try {
      const latestBlock = await getBlockNumber(config, { chainId: currentChainId });

      if (latestBlock <= state.lastSyncedBlock) return;

      const fromBlock = state.lastSyncedBlock + 1n;
      const blockGap = latestBlock - fromBlock;

      if (blockGap > MAX_REPLAY_BLOCK_WINDOW) {
        await refetchSnapshot();

        return;
      }

      const logs = await getContractEvents(config, {
        abi: ABI,
        eventName: "OfferEvent",
        address,
        chainId: currentChainId,
        fromBlock,
        toBlock: latestBlock,
      });

      await syncOfferIds(currentChainId, address, getOfferIdsFromLogs(logs));
      state.lastSyncedBlock = latestBlock;
    }
    catch {
      await refetchSnapshot();
    }
    finally {
      state.replayRunning = false;
    }
  };

  const bootstrapSync = async () => {
    try {
      const bootBlock = await getBlockNumber(config, { chainId: currentChainId });

      state.lastSyncedBlock = bootBlock > 0n ? bootBlock - 1n : 0n;
      state.syncReady = true;

      await replaySinceLastSyncedBlock();
    }
    catch {
      state.syncReady = true;
      await refetchSnapshot();
    }
  };

  const unwatch = watchContractEvent(config, {
    abi: ABI,
    address,
    chainId: currentChainId,
    eventName: "OfferEvent",
    onLogs: (logs) => {
      if (logs.length === 0) return;

      const offerIds = getOfferIdsFromLogs(logs);
      const maxBlockInBatch = getMaxBlockInBatch(logs, state.lastSyncedBlock);

      void syncOfferIds(currentChainId, address, offerIds)
        .then(() => {
          if (maxBlockInBatch !== undefined) {
            state.lastSyncedBlock = maxBlockInBatch;
          }
        })
        .catch(() => {
          void replaySinceLastSyncedBlock();
        });
    },
    onError: () => {
      void replaySinceLastSyncedBlock();
    },
  });

  const healthCheck = setInterval(() => {
    void replaySinceLastSyncedBlock();
  }, REPLAY_HEALTH_CHECK_INTERVAL);

  void bootstrapSync();

  return () => {
    unwatch();
    clearInterval(healthCheck);
  };
};

export const retainOfferSyncOwner = (currentChainId: SupportedChainId, address: `0x${string}`) => {
  const key = `${currentChainId}:${address.toLowerCase()}`;
  const existing = offerSyncOwners.get(key);

  if (existing) {
    existing.refCount += 1;
  }
  else {
    offerSyncOwners.set(key, {
      refCount: 1,
      cleanup: createOfferSyncOwner(currentChainId, address),
    });
  }

  return () => {
    const owner = offerSyncOwners.get(key);

    if (!owner) return;

    owner.refCount -= 1;

    if (owner.refCount > 0) return;

    owner.cleanup();
    offerSyncOwners.delete(key);
  };
};
