import { encodeData } from "ox/AbiFunction";
import type { Address } from "ox/Address";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "setPriceOracle",
    inputs: [
        { name: "oracle", type: "address", internalType: "address" },
        { name: "maxage", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const setPriceOracleParameters = ({
    contractAddress,
    oracle,
    maxage,
}: ContractWriteParameters<{
    oracle: Address.Address;
    maxage: bigint;
}>) => ({
    data: encodeData(abi, [oracle, maxage]),
    to: contractAddress,
});
