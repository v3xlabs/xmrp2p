import type { PublicActions } from "viem";

import { ABI } from "./abi";
export { ABI } from "./abi";
export * from "./keys/compute";
export * from "./keys/encode";
export * from "./keys/generate";

const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

export const getOffers = async (actions: PublicActions) => {
    const x = await actions.readContract({
        abi: ABI,
        functionName: "listOffers",
        args: [0n, 10n],
        address: CONTRACT_ADDRESS,
    });

    console.log(x);

    return x;
};

export const getParameters = async (actions: PublicActions) => {
    const x = await actions.readContract({
        abi: ABI,
        functionName: "parameters",
        address: CONTRACT_ADDRESS,
    });

    console.log(x);

    return x;
};
