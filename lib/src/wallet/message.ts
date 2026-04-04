import { encodeData } from "ox/AbiFunction";
import { Hex } from "ox/Hex";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "message",
    inputs: [
        { name: "offerid", type: "uint256", internalType: "uint256" },
        { name: "content", type: "bytes", internalType: "bytes" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const messageParameters = ({
    contractAddress,
    offerid,
    content,
}: ContractWriteParameters<{ offerid: bigint; content: Hex; }>) => ({
    data: encodeData(abi, [offerid, content]),
    to: contractAddress,
});
