import type { Address } from "viem/accounts";

export type EnstateResponse = { name: string | undefined; avatar: string | undefined; };

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

export const useEnsName = async (address: Address | string | undefined): Promise<EnstateResponse> => {
  console.log("fetching ens data for " + address);

  if (!address || address.toLowerCase() === ZERO_ADDRESS) return {} as EnstateResponse;

  const data = await fetch("https://enstate.rs/a/" + address);

  if (data.status === 404) return {} as EnstateResponse;

  const parsed = await data.json();

  // TODO: replace type-cast with proper zod validation lol
  return parsed as EnstateResponse;
};
