import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "takeSellOffer",
    inputs: [
        {
            name: "id",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "minxmr",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "maxprice",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "publicspendkey",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "publicviewkey",
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

export const takeSellOfferParameters = ({
    contractAddress,
    id,
    minxmr,
    maxprice,
    publicspendkey,
    publicviewkey,
    msgpubkey,
}: ContractWriteParameters<{
    id: bigint;
    minxmr: bigint;
    maxprice: bigint;
    publicspendkey: bigint;
    publicviewkey: bigint;
    msgpubkey: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        minxmr,
        maxprice,
        publicspendkey,
        publicviewkey,
        msgpubkey,
    ]),
    to: contractAddress,
});
