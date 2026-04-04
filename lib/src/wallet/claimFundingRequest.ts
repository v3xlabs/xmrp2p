import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "claimFundingRequest",
    inputs: [{ name: "addr", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const claimFundingRequestParameters = ({
    contractAddress,
    addr,
}: ContractWriteParameters<{ addr: Address; }>) => ({
    data: encodeData(abi, [addr]),
    to: contractAddress,
});
