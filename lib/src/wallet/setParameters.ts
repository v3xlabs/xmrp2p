import { encodeData } from "ox/AbiFunction";

import type { ContractWriteParameters } from "../types";

const abi = {
    type: "function",
    name: "setParameters",
    inputs: [
        { name: "FundingRequestMaxBalance", type: "uint256", internalType: "uint256" },
        { name: "FundingRequestMinFeeRatio", type: "uint256", internalType: "uint256" },
        { name: "MaximumBuyOfferBookSize", type: "uint256", internalType: "uint256" },
        { name: "MinimumBuyOffer", type: "uint256", internalType: "uint256" },
        { name: "MaximumBuyOffer", type: "uint256", internalType: "uint256" },
        { name: "MaximumSellOfferBookSize", type: "uint256", internalType: "uint256" },
        { name: "MinimumSellOffer", type: "uint256", internalType: "uint256" },
        { name: "MaximumSellOffer", type: "uint256", internalType: "uint256" },
        { name: "SellOfferCoverageRatio", type: "uint256", internalType: "uint256" },
        { name: "T0Delay", type: "uint256", internalType: "uint256" },
        { name: "T1Delay", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
} as const;

export const setParametersParameters = ({
    contractAddress,
    FundingRequestMaxBalance,
    FundingRequestMinFeeRatio,
    MaximumBuyOfferBookSize,
    MinimumBuyOffer,
    MaximumBuyOffer,
    MaximumSellOfferBookSize,
    MinimumSellOffer,
    MaximumSellOffer,
    SellOfferCoverageRatio,
    T0Delay,
    T1Delay,
}: ContractWriteParameters<{
    FundingRequestMaxBalance: bigint;
    FundingRequestMinFeeRatio: bigint;
    MaximumBuyOfferBookSize: bigint;
    MinimumBuyOffer: bigint;
    MaximumBuyOffer: bigint;
    MaximumSellOfferBookSize: bigint;
    MinimumSellOffer: bigint;
    MaximumSellOffer: bigint;
    SellOfferCoverageRatio: bigint;
    T0Delay: bigint;
    T1Delay: bigint;
}>) => ({
    data: encodeData(abi, [
        FundingRequestMaxBalance,
        FundingRequestMinFeeRatio,
        MaximumBuyOfferBookSize,
        MinimumBuyOffer,
        MaximumBuyOffer,
        MaximumSellOfferBookSize,
        MinimumSellOffer,
        MaximumSellOffer,
        SellOfferCoverageRatio,
        T0Delay,
        T1Delay,
    ]),
    to: contractAddress,
});
