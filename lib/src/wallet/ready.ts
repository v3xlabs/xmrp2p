import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "ready",
    inputs: [{ name: "id", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const readyParameters = ({
    contractAddress,
    id,
}: ContractWriteParameters<{ id: bigint; }>) => ({
    data: encodeData(abi, [id]),
    to: contractAddress,
});
