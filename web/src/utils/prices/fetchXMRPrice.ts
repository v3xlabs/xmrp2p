import { createPublicClient, http } from "viem";
import { optimism } from "viem/chains";

const XMR_USD_ORACLE = "0x2a8D91686A048E98e6CCF1A89E82f40D14312672" as const;
const CHAINLINK_DECIMALS = 8;

const CHAINLINK_AGGREGATOR_ABI = [
  {
    inputs: [],
    name: "latestRoundData",
    outputs: [
      { name: "roundId", type: "uint80" },
      { name: "answer", type: "int256" },
      { name: "startedAt", type: "uint256" },
      { name: "updatedAt", type: "uint256" },
      { name: "answeredInRound", type: "uint80" },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const client = createPublicClient({
  chain: optimism,
  transport: http(),
});

export const fetchXMRPrice = async (): Promise<number> => {
  const [, answer] = await client.readContract({
    address: XMR_USD_ORACLE,
    abi: CHAINLINK_AGGREGATOR_ABI,
    functionName: "latestRoundData",
  });

  return Number(answer) / 10 ** CHAINLINK_DECIMALS;
};
