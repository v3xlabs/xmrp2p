import type { PublicActions } from "viem";

import { ABI } from "./abi";
export { ABI } from "./abi";

const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

export const getOffers = async (actions: PublicActions) => {
    const x = await actions.readContract({
        abi: ABI,
        functionName: "offers",
        args: [0n],
        address: CONTRACT_ADDRESS,
    });

    console.log(x);
};

export const getParameters = async (actions: PublicActions) => {
    const x = await actions.readContract({
        abi: ABI,
        functionName: "parameters",
        address: CONTRACT_ADDRESS,
    });

    console.log(x);
};
