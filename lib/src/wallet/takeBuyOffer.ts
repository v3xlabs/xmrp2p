import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "takeBuyOffer",
    inputs: [
        {
            name: "id",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "maxxmr",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "minprice",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "publicspendkey",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "privateviewkey",
            type: "uint256",
            internalType: "uint256",
        },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const takeBuyOfferParameters = ({
    contractAddress,
    id,
    maxxmr,
    minprice,
    publicspendkey,
    privateviewkey,
}: ContractWriteParameters<{
    id: bigint;
    maxxmr: bigint;
    minprice: bigint;
    publicspendkey: bigint;
    privateviewkey: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        maxxmr,
        minprice,
        publicspendkey,
        privateviewkey,
    ]),
    to: contractAddress,
});
