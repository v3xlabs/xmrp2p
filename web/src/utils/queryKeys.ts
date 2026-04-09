export const queryKeys = {
  offers: {
    all: (chainId: number) => ["c", chainId, "offers"] as const,
  },
  parameters: (chainId: number) => ["c", chainId, "parameters"] as const,
  prepareOrder: (chainId: number, offerType: number, rate: bigint, ethAmount: bigint) =>
    ["c", chainId, "prepareOrder", offerType, rate, ethAmount] as const,
  marketRate: () => ["market-rate", "xmr-eth"] as const,
  blockTimestamp: (blockNumber?: string) => ["blockTimestamp", blockNumber] as const,
  moneroHeight: (timestamp?: number) => ["moneroHeight", timestamp] as const,
  address: (address: string) => ["addy", address] as const,
};
