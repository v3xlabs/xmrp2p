import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

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
            name: "minxmr",
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
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const createBuyOfferParameters = ({
    contractAddress,
    counterparty,
    price,
    minxmr,
    publicspendkey,
    publicviewkey,
}: ContractWriteParameters<{
    counterparty: Address;
    price: bigint;
    minxmr: bigint;
    publicspendkey: bigint;
    publicviewkey: bigint;
}>) => ({
    data: encodeData(abi, [
        counterparty,
        price,
        minxmr,
        publicspendkey,
        publicviewkey,
    ]),
    to: contractAddress,
});
