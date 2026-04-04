import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "listFundingRequests",
    inputs: [
        { name: "offset", type: "uint256", internalType: "uint256" },
        { name: "count", type: "uint256", internalType: "uint256" },
    ],
    outputs: [
        {
            name: "",
            type: "tuple[]",
            internalType: "struct FundingRequest[]",
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

export const listFundingRequests = async ({
    provider,
    contractAddress,
    offset,
    count,
}: ContractRead<{ offset: bigint; count: bigint; }>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [offset, count]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
