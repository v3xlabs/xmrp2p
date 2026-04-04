import { decodeResult, encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "getFundingRequest",
    inputs: [
        {
            name: "requester",
            type: "address",
            internalType: "address",
        },
    ],
    outputs: [
        {
            name: "",
            type: "tuple",
            internalType: "struct FundingRequest",
            components: [
                { name: "requester", type: "address", internalType: "address" },
                { name: "amount", type: "uint256", internalType: "uint256" },
                { name: "fee", type: "uint256", internalType: "uint256" },
                { name: "funder", type: "address", internalType: "address" },
                { name: "index", type: "uint256", internalType: "uint256" },
                { name: "usedby", type: "uint256", internalType: "uint256" },
                { name: "fundedOn", type: "uint256", internalType: "uint256" },
            ],
        },
    ],
    stateMutability: "view",
} as const;

export const getFundingRequest = async ({
    provider,
    contractAddress,
    requester,
}: ContractRead<{ requester: Address.Address; }>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [requester]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
