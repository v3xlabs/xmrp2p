import type { Address } from "viem/accounts";

export type EnstateResponse = { name: string | undefined; avatar: string | undefined; };

export const useEnsName = async (address: Address | string | undefined): Promise<EnstateResponse> => {
    console.log("fetching ens data for " + address);

    if (!address) return {} as EnstateResponse;

    const data = await fetch("https://enstate.rs/a/" + address);

    const parsed = await data.json();

    // TODO: replace type-cast with proper zod validation lol
    return parsed as EnstateResponse;
};
