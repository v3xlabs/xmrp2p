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
        {
            name: "msgpubkey",
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
    msgpubkey,
}: ContractWriteParameters<{
    id: bigint;
    maxxmr: bigint;
    minprice: bigint;
    publicspendkey: bigint;
    privateviewkey: bigint;
    msgpubkey: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        maxxmr,
        minprice,
        publicspendkey,
        privateviewkey,
        msgpubkey,
    ]),
    to: contractAddress,
});
