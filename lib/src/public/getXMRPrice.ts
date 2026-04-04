import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "getXMRPrice",
    inputs: [
        { name: "offerType", type: "uint8", internalType: "enum OfferType" },
        { name: "offerPrice", type: "uint256", internalType: "uint256" },
        { name: "offerOracleRatio", type: "uint256", internalType: "uint256" },
        { name: "offerOracleOffset", type: "int256", internalType: "int256" },
        { name: "price", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
} as const;

export const getXMRPrice = async ({
    provider,
    contractAddress,
    offerType,
    offerPrice,
    offerOracleRatio,
    offerOracleOffset,
    price,
}: ContractRead<{
    offerType: number;
    offerPrice: bigint;
    offerOracleRatio: bigint;
    offerOracleOffset: bigint;
    price: bigint;
}>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [offerType, offerPrice, offerOracleRatio, offerOracleOffset, price]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
