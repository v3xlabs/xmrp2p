import { createMemo, createSignal } from "solid-js";
import { parseEther } from "viem";

import { useMarketRate } from "../utils/prices/useMarketRate";
import { useApp } from "./useApp";

const formatNum = (n: number): string => {
  if (Number.isNaN(n) || !Number.isFinite(n)) return "";

  return Number.parseFloat(n.toFixed(8)).toString();
};

const computeBuy = (sell: number, rate: number, fromToken: string): number =>
  (fromToken === "xmr" ? sell / rate : sell * rate);

const computeSell = (buy: number, rate: number, fromToken: string): number =>
  (fromToken === "xmr" ? buy * rate : buy / rate);

const computeRate = (
  sell: number,
  buy: number,
  fromToken: string,
): number => (fromToken === "xmr" ? sell / buy : buy / sell);

export const useSwap = () => {
  const { parameters } = useApp();
  const [fromToken, setFromToken] = createSignal("xmr");
  const [toToken, setToToken] = createSignal("eth");
  const [sellAmount, setSellAmount] = createSignal("");
  const [buyAmount, setBuyAmount] = createSignal("");
  const [rate, setRate] = createSignal("");

  const marketRate = useMarketRate();

  const rateValue = createMemo(() => (rate() ? BigInt(Math.round(Number.parseFloat(rate()) * 10 ** 12)) : undefined));

  const suggestedRate = () => marketRate.data?.xmrPerEth ?? null;

  const handleToChange = (value: string) => {
    if (value === fromToken()) setFromToken(toToken());

    setToToken(value);
  };

  const handleFromChange = (value: string) => {
    if (value === toToken()) setToToken(fromToken());

    setFromToken(value);
  };

  const handleSellChange = (value: string) => {
    setSellAmount(value);

    const sell = Number.parseFloat(value);

    if (Number.isNaN(sell) || sell <= 0) return;

    const r = Number.parseFloat(rate());

    if (!Number.isNaN(r) && r > 0) {
      setBuyAmount(formatNum(computeBuy(sell, r, fromToken())));
    }
    else {
      const buy = Number.parseFloat(buyAmount());

      if (!Number.isNaN(buy) && buy > 0) {
        setRate(formatNum(computeRate(sell, buy, fromToken())));
      }
    }
  };

  const handleBuyChange = (value: string) => {
    setBuyAmount(value);

    const buy = Number.parseFloat(value);

    if (Number.isNaN(buy) || buy <= 0) return;

    const r = Number.parseFloat(rate());

    if (!Number.isNaN(r) && r > 0) {
      setSellAmount(formatNum(computeSell(buy, r, fromToken())));
    }
    else {
      const sell = Number.parseFloat(sellAmount());

      if (!Number.isNaN(sell) && sell > 0) {
        setRate(formatNum(computeRate(sell, buy, fromToken())));
      }
    }
  };

  const applyRate = (rateValue: string) => {
    setRate(rateValue);

    const r = Number.parseFloat(rateValue);

    if (Number.isNaN(r) || r <= 0) return;

    const sell = Number.parseFloat(sellAmount());

    if (!Number.isNaN(sell) && sell > 0) {
      setBuyAmount(formatNum(computeBuy(sell, r, fromToken())));

      return;
    }

    const buy = Number.parseFloat(buyAmount());

    if (!Number.isNaN(buy) && buy > 0) {
      setSellAmount(formatNum(computeSell(buy, r, fromToken())));
    }
  };

  const handleUseSuggestedRate = () => {
    const sr = suggestedRate();

    if (sr == null) return;

    applyRate(formatNum(sr));
  };

  const handleSwapTokens = () => {
    const tempToken = fromToken();

    setFromToken(toToken());
    setToToken(tempToken);

    const tempAmount = sellAmount();

    setSellAmount(buyAmount());
    setBuyAmount(tempAmount);
  };

  const offerType = () => (fromToken() === "eth" ? 1 : 2);

  const depositAmount = createMemo(() => {
    const deposit_ratio = BigInt(parameters.data?.[2] ?? 0);
    const denominator = 10_000n;

    console.log({ deposit_ratio, denominator });

    const raw = fromToken() === "eth" ? sellAmount() : buyAmount();
    const rawx = Number.parseFloat(raw) > 0 ? parseEther(raw) : 0n;

    return ((rawx * deposit_ratio) / denominator);
  });

  const ethAmount = () => {
    const raw = fromToken() === "eth" ? sellAmount() : depositAmount();

    if (typeof raw === "bigint") return raw;

    return raw && Number.parseFloat(raw) > 0 ? parseEther(raw) : 0n;
  };

  return {
    fromToken,
    handleToChange,
    toToken,
    handleFromChange,
    offerType,
    marketRate,
    ethAmount,
    handleSwapTokens,
    handleUseSuggestedRate,
    handleSellChange,
    handleBuyChange,
    applyRate,
    rateValue,
    buyAmount,
    sellAmount,
    suggestedRate,
    rate,
    depositAmount,
  };
};
