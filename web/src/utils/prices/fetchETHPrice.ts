import { createPublicClient, http } from "viem";
import { optimism } from "viem/chains";

const ETH_USD_ORACLE = "0x13e3Ee699D1909E989722E753853AE30b17e08c5" as const;
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

export const fetchETHPrice = async (): Promise<number> => {
  const [, answer] = await client.readContract({
    address: ETH_USD_ORACLE,
    abi: CHAINLINK_AGGREGATOR_ABI,
    functionName: "latestRoundData",
  });

  return Number(answer) / 10 ** CHAINLINK_DECIMALS;
};
