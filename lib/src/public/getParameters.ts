import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "getParameters",
    inputs: [],
    outputs: [
        {
            name: "",
            type: "tuple",
            internalType: "struct MoneroSwap.Parameters",
            components: [
                {
                    name: "FUNDING_REQUEST_MAXBALANCE",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "FUNDING_REQUEST_MIN_FEE_RATIO",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MINIMUM_BUY_OFFER",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MAXIMUM_BUY_OFFER",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MINIMUM_SELL_OFFER",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MAXIMUM_SELL_OFFER",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MAXIMUM_BUY_OFFER_BOOK_SIZE",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "MAXIMUM_SELL_OFFER_BOOK_SIZE",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "SELL_OFFER_COVERAGE_RATIO",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "T0_DELAY",
                    type: "uint256",
                    internalType: "uint256",
                },
                {
                    name: "T1_DELAY",
                    type: "uint256",
                    internalType: "uint256",
                },
            ],
        },
    ],
    stateMutability: "view",
} as const;

export const getParameters = async ({
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
