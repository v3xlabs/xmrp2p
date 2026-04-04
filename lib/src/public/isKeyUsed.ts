import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "isKeyUsed",
    inputs: [{ name: "key", type: "uint256", internalType: "uint256" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
} as const;

export const isKeyUsed = async ({
    provider,
    contractAddress,
    key,
}: ContractRead<{ key: bigint; }>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [key]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
