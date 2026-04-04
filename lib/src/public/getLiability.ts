import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "getLiability",
    inputs: [],
    outputs: [
        {
            name: "",
            type: "uint256",
            internalType: "uint256",
        },
    ],
    stateMutability: "view",
} as const;

export const getLiability = async ({
    provider,
    contractAddress,
}: ContractRead) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
