import { decodeResult, encodeData } from "ox/AbiFunction";

import { ContractRead } from "../types";

const abi = {
    type: "function",
    name: "getBuyOffer",
    inputs: [
        {
            name: "id",
            type: "uint256",
            internalType: "uint256",
        },
    ],
    outputs: [
        {
            name: "",
            type: "tuple",
            internalType: "struct Offer",
            components: [
                { name: "type_", type: "uint8", internalType: "enum OfferType" },
                { name: "state", type: "uint8", internalType: "enum OfferState" },
                { name: "funded", type: "bool", internalType: "bool" },
                { name: "owner", type: "address", internalType: "address" },
                { name: "manager", type: "address", internalType: "address" },
                { name: "counterparty", type: "address", internalType: "address" },
                { name: "id", type: "uint256", internalType: "uint256" },
                { name: "maxamount", type: "uint256", internalType: "uint256" },
                { name: "price", type: "uint256", internalType: "uint256" },
                { name: "oracleRatio", type: "uint256", internalType: "uint256" },
                { name: "oracleOffset", type: "int256", internalType: "int256" },
                { name: "minxmr", type: "uint256", internalType: "uint256" },
                { name: "maxxmr", type: "uint256", internalType: "uint256" },
                { name: "maxprice", type: "uint256", internalType: "uint256" },
                { name: "minprice", type: "uint256", internalType: "uint256" },
                { name: "deposit", type: "uint256", internalType: "uint256" },
                { name: "lastupdate", type: "uint256", internalType: "uint256" },
                { name: "blockTaken", type: "uint256", internalType: "uint256" },
                { name: "evmPublicSpendKey", type: "uint256", internalType: "uint256" },
                { name: "evmPrivateSpendKey", type: "uint256", internalType: "uint256" },
                { name: "evmPublicViewKey", type: "uint256", internalType: "uint256" },
                { name: "evmPrivateViewKey", type: "uint256", internalType: "uint256" },
                { name: "xmrPublicSpendKey", type: "uint256", internalType: "uint256" },
                { name: "xmrPrivateSpendKey", type: "uint256", internalType: "uint256" },
                { name: "xmrPrivateViewKey", type: "uint256", internalType: "uint256" },
                { name: "index", type: "uint256", internalType: "uint256" },
                { name: "finalprice", type: "uint256", internalType: "uint256" },
                { name: "takerDeposit", type: "uint256", internalType: "uint256" },
                { name: "finalxmr", type: "uint256", internalType: "uint256" },
                { name: "t0", type: "uint256", internalType: "uint256" },
                { name: "t1", type: "uint256", internalType: "uint256" },
                { name: "xmrPublicMsgKey", type: "uint256", internalType: "uint256" },
                { name: "evmPublicMsgKey", type: "uint256", internalType: "uint256" },
            ],
        },
    ],
    stateMutability: "view",
} as const;

export const getBuyOffer = async ({
    provider,
    contractAddress,
    id,
}: ContractRead<{ id: bigint; }>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [id]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
