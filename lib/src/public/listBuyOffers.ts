import { decodeResult, encodeData } from "ox/AbiFunction";

import { ABI } from "../abi";
import { ContractRead } from "../types";

type MyType = Extract<typeof ABI[number], { name: "listBuyOffers"; }>;
const abi: MyType = ABI.find(item => item["name"] === "listBuyOffers")! as MyType;

export const listBuyOffers = async ({
    provider,
    contractAddress,
    offset,
    count,
}: ContractRead<{ offset: bigint; count: bigint; }>) => {
    const result = await provider.request({
        method: "eth_call",
        params: [
            {
                to: contractAddress,
                data: encodeData(abi, [offset, count]),
            },
            "latest",
        ],
    });

    return decodeResult(abi, result);
};
