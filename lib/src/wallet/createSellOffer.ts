import { encodeData } from "ox/AbiFunction";
import { Address } from "ox/Address";

import type { ContractCall } from "../types";

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
            name: "oracleRatio",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "oracleOffset",
            type: "int256",
            internalType: "int256",
        },
        {
            name: "minxmr",
            type: "uint256",
            internalType: "uint256",
        },
        {
            name: "minprice",
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
        {
            name: "msgpubkey",
            type: "uint256",
            internalType: "uint256",
        },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const createSellOffer = ({
    provider,
    contractAddress,
    counterparty,
    price,
    oracleRatio,
    oracleOffset,
    minxmr,
    minprice,
    maxxmr,
    publicspendkey,
    privateviewkey,
    msgpubkey,
}: ContractCall<{
    counterparty: Address;
    price: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minxmr: bigint;
    minprice: bigint;
    maxxmr: bigint;
    publicspendkey: bigint;
    privateviewkey: bigint;
    msgpubkey: bigint;
}>) =>
    provider.request({
        method: "eth_call",
        params: [
            {
                data: encodeData(abi, [
                    counterparty,
                    price,
                    oracleRatio,
                    oracleOffset,
                    minxmr,
                    minprice,
                    maxxmr,
                    publicspendkey,
                    privateviewkey,
                    msgpubkey,
                ]),
                to: contractAddress,
            },
        ],
    });
