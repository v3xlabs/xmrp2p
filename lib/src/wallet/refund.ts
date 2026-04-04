import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "refund",
    inputs: [
        { name: "id", type: "uint256", internalType: "uint256" },
        { name: "privateSpendKey", type: "uint256", internalType: "uint256" },
        { name: "privateViewKey", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const refundParameters = ({
    contractAddress,
    id,
    privateSpendKey,
    privateViewKey,
}: ContractWriteParameters<{
    id: bigint;
    privateSpendKey: bigint;
    privateViewKey: bigint;
}>) => ({
    data: encodeData(abi, [id, privateSpendKey, privateViewKey]),
    to: contractAddress,
});
