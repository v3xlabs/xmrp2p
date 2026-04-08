import { type Accessor, type Component, createMemo } from "solid-js";
import { formatUnits } from "viem";

import { useMarketRate } from "../utils/prices/useMarketRate";

const DENOMINATOR = 100_000;

export const Price: Component<{ token: Accessor<string>; amount: Accessor<bigint>; }> = ({ token, amount }) => {
  const market = useMarketRate();

  const price = createMemo(() => {
    if (token() === "eth" && market.data?.ethUsd) {
      return amount() * BigInt(Math.ceil(market.data?.ethUsd * DENOMINATOR)) / BigInt(DENOMINATOR);
    }

    if (token() === "xmr" && market.data?.xmrUsd) {
      return amount() * BigInt(Math.ceil(market.data?.xmrUsd * DENOMINATOR)) / BigInt(DENOMINATOR);
    }

    return 0n;
  });

  const decimals = () => (token() === "eth" ? 18 : 12);

  const formattedPrice = () => formatUnits(price(), decimals());

  const truncatedPrice = () => {
    const truncated = formattedPrice().split(".")[0];
    const decimals = formattedPrice().split(".")[1];
    const truncatedDecimals = decimals?.slice(0, 2) ?? "";

    return `${truncated}${truncatedDecimals ? "." + truncatedDecimals : ""}`;
  };

  return (
    <div>
      $
      {truncatedPrice()}
    </div>
  );
};
