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
        { name: "minxmr", type: "uint256", internalType: "uint256" },
        { name: "maxxmr", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "payable",
} as const;

export const updateSellOfferParameters = ({
    contractAddress,
    id,
    counterparty,
    price,
    minxmr,
    maxxmr,
}: ContractWriteParameters<{
    id: bigint;
    counterparty: Address;
    price: bigint;
    minxmr: bigint;
    maxxmr: bigint;
}>) => ({
    data: encodeData(abi, [
        id,
        counterparty,
        price,
        minxmr,
        maxxmr,
    ]),
    to: contractAddress,
});
