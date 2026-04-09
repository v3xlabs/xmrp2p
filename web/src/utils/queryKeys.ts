export const queryKeys = {
  offers: {
    all: (chainId: number) => ["c", chainId, "offers"] as const,
    single: (chainId: number, offerId: bigint) => ["c", chainId, "offers", offerId] as const,
  },
  parameters: (chainId: number) => ["c", chainId, "parameters"] as const,
  prepareOrder: (chainId: number, offerType: number, rate: bigint, ethAmount: bigint) =>
    ["c", chainId, "prepareOrder", offerType, rate, ethAmount] as const,
  simulate: {
    cancel: (chainId: number, offerId: bigint) =>
      ["c", chainId, "simulate", "cancel", offerId] as const,
    take: (chainId: number, offerId: bigint, publicSpendKey: bigint, viewKey: bigint) =>
      ["c", chainId, "simulate", "take", offerId, publicSpendKey, viewKey] as const,
    ready: (chainId: number, offerId: bigint) =>
      ["c", chainId, "simulate", "ready", offerId] as const,
    claim: (chainId: number, offerId: bigint, privateSpendKey: bigint) =>
      ["c", chainId, "simulate", "claim", offerId, privateSpendKey] as const,
    quit: (chainId: number, offerId: bigint, privateSpendKey: bigint, privateViewKey: bigint) =>
      ["c", chainId, "simulate", "quit", offerId, privateSpendKey, privateViewKey] as const,
  },
  offerEvents: (chainId: number, offerId: bigint, lastupdate: bigint) =>
    ["c", chainId, "offerEvents", offerId, lastupdate] as const,
  marketRate: () => ["market-rate", "xmr-eth"] as const,
  blockTimestamp: (blockNumber?: string) => ["blockTimestamp", blockNumber] as const,
  moneroHeight: (timestamp?: number) => ["moneroHeight", timestamp] as const,
  address: (address: string) => ["addy", address] as const,
};
