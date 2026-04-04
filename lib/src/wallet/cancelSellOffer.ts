import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "cancelSellOffer",
    inputs: [{ name: "id", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const cancelSellOfferParameters = ({
    contractAddress,
    id,
}: ContractWriteParameters<{ id: bigint; }>) => ({
    data: encodeData(abi, [id]),
    to: contractAddress,
});
