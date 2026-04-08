import { SegmentedControl } from "@kobalte/core/segmented-control";
import { useMutation } from "@tanstack/solid-query";
import { writeContract } from "@wagmi/solid/actions";
import { FaSolidUpDown } from "solid-icons/fa";
import { createMemo, createSignal, For, Show, Suspense } from "solid-js";
import { match } from "ts-pattern";
import { formatEther, parseEther } from "viem";
import { english, generateMnemonic } from "viem/accounts";
import { anvil } from "viem/chains";
import { ABI, generateMoneroKeys } from "xmrp2p";

import { config, queryClient } from "../config";
import { useApp } from "../hooks/useApp";
import { useMarketRate } from "../utils/prices/useMarketRate";
import { TokenSelector } from "./TokenSelector";

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

export const Swap = () => {
  const { contractAddress, parameters, chainId } = useApp();
  const [fromToken, setFromToken] = createSignal("xmr");
  const [toToken, setToToken] = createSignal("eth");
  const [sellAmount, setSellAmount] = createSignal("");
  const [buyAmount, setBuyAmount] = createSignal("");
  const [rate, setRate] = createSignal("");

  const marketRate = useMarketRate();

  const suggestedRate = () => marketRate.data?.xmrPerEth ?? null;

  const setFromTokenSafe = (value: string) => {
    if (value === toToken()) setToToken(fromToken());

    setFromToken(value);
  };

  const setToTokenSafe = (value: string) => {
    if (value === fromToken()) setFromToken(toToken());

    setToToken(value);
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

  const createOffer = useMutation(() => ({
    mutationFn: async () => {
      // from floating point to piconeros per eth
      const rateValue = BigInt(Math.round(Number.parseFloat(rate()) * 10 ** 12));
      // const seedphrase = "test test test test test test test test test junk junk junk";
      const seedphrase = generateMnemonic(english);
      const { publicSpendKey, publicViewKey } = generateMoneroKeys(seedphrase);

      console.log({ ethAmount: ethAmount(), offerType: offerType(), rateValue });

      const hash = await writeContract(config, {
        abi: ABI,
        functionName: "offer",
        args: [
          offerType(),
          rateValue,
          "0x0000000000000000000000000000000000000000",
          publicSpendKey,
          publicViewKey,
        ],
        address: contractAddress(),
        value: ethAmount(),
        // eslint-disable-next-line no-restricted-syntax
        chainId: anvil.id,
      });

      console.log({ hash });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["offers"] });
    },
  }));

  const isFormValid = () => {
    const sell = Number.parseFloat(sellAmount());
    const buy = Number.parseFloat(buyAmount());
    const r = Number.parseFloat(rate());

    return (
      !Number.isNaN(sell)
      && sell > 0
      && !Number.isNaN(buy)
      && buy > 0
      && !Number.isNaN(r)
      && r > 0
    );
  };

  return (
    <div class="card p-4 space-y-2">
      <div>
        <div class="flex justify-between items-center gap-1">
          <label for="input_amount" class="text-md py-1">
            Sell
          </label>
          <TokenSelector token={fromToken} setToken={setFromTokenSafe} />
        </div>
        <input
          placeholder="0"
          class="input w-full"
          id="input_amount"
          type="text"
          inputMode="decimal"
          value={sellAmount()}
          onInput={e => handleSellChange(e.currentTarget.value)}
        />
      </div>

      <div class="flex justify-center -my-4">
        <button
          class="aspect-square p-2 group border border-(--thorin-border) rounded-md bg-(--thorin-background-primary) hover:bg-(--thorin-background-secondary) hover:cursor-pointer"
          onClick={handleSwapTokens}
        >
          <FaSolidUpDown class="group-hover:rotate-180 transition-all w-4 h-4" />
        </button>
      </div>

      <div>
        <div class="flex justify-between items-center gap-1">
          <label for="output_amount" class="text-md py-1">
            Buy
          </label>
          <TokenSelector token={toToken} setToken={setToTokenSafe} />
        </div>
        <input
          placeholder="0"
          class="input w-full"
          id="output_amount"
          type="text"
          inputMode="decimal"
          value={buyAmount()}
          onInput={e => handleBuyChange(e.currentTarget.value)}
        />
      </div>

      <div>
        <div class="flex justify-between items-center mb-1">
          <label class="text-sm text-(--thorin-text-secondary)">Rate</label>
          {match(marketRate)
            .when(
              q => q.isPending,
              () => (
                <span class="text-xs text-(--thorin-text-disabled)">
                  Fetching market rate...
                </span>
              ),
            )
            .when(
              q => q.isError,
              () => (
                <span class="text-xs text-(--thorin-red-primary)">
                  Rate unavailable
                </span>
              ),
            )
            .otherwise(() => (
              <Show when={suggestedRate()}>
                {sr => (
                  <button
                    class="text-xs text-(--thorin-blue-primary) hover:text-(--thorin-blue-bright) cursor-pointer transition-colors"
                    onClick={handleUseSuggestedRate}
                  >
                    Market ≈
                    {" "}
                    {sr().toFixed(2)}
                    {" "}
                    XMR/ETH
                  </button>
                )}
              </Show>
            ))}
        </div>
        <div class="relative">
          <input
            placeholder="0"
            class="input w-full pr-20"
            type="text"
            inputMode="decimal"
            value={rate()}
            onInput={e => applyRate(e.currentTarget.value)}
          />
          <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-(--thorin-text-secondary) pointer-events-none">
            XMR/ETH
          </span>
        </div>
      </div>

      <div>
        <SegmentedControl
          class="flex justify-between gap-2"
          defaultValue="1"
        >
          <SegmentedControl.Label class="segmented-control__label">
            Slippage
          </SegmentedControl.Label>
          <div
            class="w-fit border border-(--thorin-border) rounded-md relative overflow-hidden"
            role="presentation"
          >
            <SegmentedControl.Indicator class="absolute bottom-0 h-1 bg-(--thorin-blue-primary) transition-all not-last:-ml-px" />
            <div
              class="inline-flex flex-row divide-x divide-(--thorin-border)"
              role="presentation"
            >
              <For each={["3%", "5%", "10%"]}>
                {slippage => (
                  <SegmentedControl.Item
                    value={slippage}
                    class="relative px-2"
                  >
                    <SegmentedControl.ItemInput />
                    <SegmentedControl.ItemLabel class="data-checked:text-(--thorin-text-accent) not-data-checked:cursor-pointer data-checked:pointer-none">
                      {slippage}
                    </SegmentedControl.ItemLabel>
                  </SegmentedControl.Item>
                )}
              </For>
            </div>
          </div>
        </SegmentedControl>
      </div>

      <Suspense>
        <Show when={depositAmount()}>
          <div>
            You are sending:
            {" "}
            {formatEther(depositAmount())}
            {" "}
            ETH
          </div>
        </Show>
      </Suspense>

      <button
        class="btn-primary btn-lg w-full"
        disabled={createOffer.isPending || !isFormValid() || ethAmount() === 0n}
        onClick={() => createOffer.mutate()}
      >
        Create Order
      </button>
    </div>
  );
};
