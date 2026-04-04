import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "createFundingRequest",
    inputs: [
        { name: "amount", type: "uint256", internalType: "uint256" },
        { name: "fee", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const createFundingRequestParameters = ({
    contractAddress,
    amount,
    fee,
}: ContractWriteParameters<{ amount: bigint; fee: bigint; }>) => ({
    data: encodeData(abi, [amount, fee]),
    to: contractAddress,
});
