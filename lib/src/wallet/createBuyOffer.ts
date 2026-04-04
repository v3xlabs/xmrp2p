import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractCall } from "../types";

const abi = {
    type: "function",
    name: "createBuyOffer",
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

export const createBuyOffer = ({ provider, contractAddress,
    counterparty,
    price,
    oracleRatio,
    oracleOffset,
    minxmr,
    maxprice,
    publicspendkey,
    publicviewkey,
    msgpubkey,
}: ContractCall<{
    counterparty: Address;
    price: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minxmr: bigint;
    maxprice: bigint;
    publicspendkey: bigint;
    publicviewkey: bigint;
    msgpubkey: bigint;
}>) => provider.request({
    method: "eth_call",
    params: [{
        data: encodeData(abi, [
            counterparty, price, oracleRatio, oracleOffset, minxmr, maxprice, publicspendkey, publicviewkey, msgpubkey,
        ]),
        to: contractAddress,
    }],

});
