import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "updateSellOffer",
    inputs: [
        { name: "id", type: "uint256", internalType: "uint256" },
        { name: "counterparty", type: "address", internalType: "address" },
        { name: "price", type: "uint256", internalType: "uint256" },
        { name: "oracleRatio", type: "uint256", internalType: "uint256" },
        { name: "oracleOffset", type: "int256", internalType: "int256" },
        { name: "minxmr", type: "uint256", internalType: "uint256" },
        { name: "minprice", type: "uint256", internalType: "uint256" },
        { name: "maxxmr", type: "uint256", internalType: "uint256" },
        { name: "msgpubkey", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const updateSellOfferParameters = ({
    contractAddress,
    id,
    counterparty,
    price,
    oracleRatio,
    oracleOffset,
    minxmr,
    minprice,
    maxxmr,
    msgpubkey,
}: ContractWriteParameters<{
    id: bigint;
    counterparty: Address;
    price: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minxmr: bigint;
    minprice: bigint;
    maxxmr: bigint;
    msgpubkey: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        counterparty,
        price,
        oracleRatio,
        oracleOffset,
        minxmr,
        minprice,
        maxxmr,
        msgpubkey,
    ]),
    to: contractAddress,
});
