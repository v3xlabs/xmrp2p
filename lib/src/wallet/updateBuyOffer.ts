import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "updateBuyOffer",
    inputs: [
        { name: "id", type: "uint256", internalType: "uint256" },
        { name: "counterparty", type: "address", internalType: "address" },
        { name: "maxamount", type: "uint256", internalType: "uint256" },
        { name: "price", type: "uint256", internalType: "uint256" },
        { name: "oracleRatio", type: "uint256", internalType: "uint256" },
        { name: "oracleOffset", type: "int256", internalType: "int256" },
        { name: "minxmr", type: "uint256", internalType: "uint256" },
        { name: "maxprice", type: "uint256", internalType: "uint256" },
        { name: "msgpubkey", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const updateBuyOfferParameters = ({
    contractAddress,
    id,
    counterparty,
    maxamount,
    price,
    oracleRatio,
    oracleOffset,
    minxmr,
    maxprice,
    msgpubkey,
}: ContractWriteParameters<{
    id: bigint;
    counterparty: Address.Address;
    maxamount: bigint;
    price: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minxmr: bigint;
    maxprice: bigint;
    msgpubkey: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        counterparty,
        maxamount,
        price,
        oracleRatio,
        oracleOffset,
        minxmr,
        maxprice,
        msgpubkey,
    ]),
    to: contractAddress,
});
