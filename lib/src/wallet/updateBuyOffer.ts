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
        { name: "minxmr", type: "uint256", internalType: "uint256" },
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
    minxmr,
}: ContractWriteParameters<{
    id: bigint;
    counterparty: Address;
    maxamount: bigint;
    price: bigint;
    minxmr: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        counterparty,
        maxamount,
        price,
        minxmr,
    ]),
    to: contractAddress,
});
