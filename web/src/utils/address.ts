import type { Address } from "viem";

export const truncateAddress = (address: string | Address | undefined) => (address ? address.slice(0, 5) + "..." + address.slice(-5) : undefined);
