import { encodeData } from "ox/AbiFunction";
import { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "createSellOffer",
    inputs: [
        {
            name: "counterparty",
            type: "address",
            internalType: "address",
        },
        {
            name: "price",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "minxmr",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "maxxmr",
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

export const createSellOfferParameters = ({
    contractAddress,
    counterparty,
    price,
    minxmr,
    maxxmr,
    publicspendkey,
    privateviewkey,
}: ContractWriteParameters<{
    counterparty: Address;
    price: bigint;
    minxmr: bigint;
    maxxmr: bigint;
    publicspendkey: bigint;
    privateviewkey: bigint;
}>) => ({
    data: encodeData(abi, [
        counterparty,
        price,
        minxmr,
        maxxmr,
        publicspendkey,
        privateviewkey,
    ]),
    to: contractAddress,
});
