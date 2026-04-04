import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "cancelFundingRequest",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const cancelFundingRequestParameters = ({
    contractAddress,
}: ContractWriteParameters) => ({
    data: encodeData(abi),
    to: contractAddress,
});
