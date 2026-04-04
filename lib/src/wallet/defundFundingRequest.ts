import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "defundFundingRequest",
    inputs: [{ name: "addr", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const defundFundingRequestParameters = ({
    contractAddress,
    addr,
}: ContractWriteParameters<{ addr: Address.Address; }>) => ({
    data: encodeData(abi, [addr]),
    to: contractAddress,
});
