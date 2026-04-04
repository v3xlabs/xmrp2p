import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "claim",
    inputs: [
        { name: "id", type: "uint256", internalType: "uint256" },
        { name: "privateSpendKey", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const claimParameters = ({
    contractAddress,
    id,
    privateSpendKey,
}: ContractWriteParameters<{ id: bigint; privateSpendKey: bigint; }>) => ({
    data: encodeData(abi, [id, privateSpendKey]),
    to: contractAddress,
});
