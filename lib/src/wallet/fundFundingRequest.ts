import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "fundFundingRequest",
    inputs: [
        {
            name: "requester",
            type: "address",
            internalType: "address",
        },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const fundFundingRequestParameters = ({
    contractAddress,
    requester,
}: ContractWriteParameters<{
    requester: Address;
}>) => ({
    data: encodeData(abi, [requester]),
    to: contractAddress,
});
