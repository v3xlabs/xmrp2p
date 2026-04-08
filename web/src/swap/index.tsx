import { SegmentedControl } from "@kobalte/core/segmented-control";
import { FaSolidUpDown } from "solid-icons/fa";
import { For, Show, Suspense } from "solid-js";
import { match } from "ts-pattern";
import { formatEther } from "viem";

import ethIcon from "../assets/eth.svg";
import { useCreateOrder } from "../hooks/useCreateOrder";
import { TokenSelector } from "./TokenSelector";

export const Swap = () => {
  const {
    prepareOrder,
    createOffer,
    offerType,
    swap: {
      applyRate,
      fromToken,
      toToken,
      handleSwapTokens,
      handleUseSuggestedRate,
      marketRate,
      handleToChange,
      handleFromChange,
      buyAmount,
      handleBuyChange,
      sellAmount,
      handleSellChange,
      suggestedRate,
      rate,
      depositAmount,
    } } = useCreateOrder();

  return (
    <div class="card p-4 space-y-2">
      <div>
        <div class="flex justify-between items-center gap-1">
          <label for="input_amount" class="text-md py-1">
            Sell
          </label>
          <TokenSelector token={fromToken} setToken={handleFromChange} />
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
          <TokenSelector token={toToken} setToken={handleToChange} />
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

      {/* <div>
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
      </div> */}

      <Suspense>
        <Show when={depositAmount() && offerType() === 2}>
          <div class="flex items-center justify-between">
            <div>
              Deposit
            </div>
            <div class="inline-flex items-center gap-1">
              {formatEther(depositAmount())}
              {" "}
              ETH
              {" "}
              <img src={ethIcon} alt="ETH" class="w-4 h-4" />
            </div>
          </div>
        </Show>
      </Suspense>

      <button
        class="btn-primary btn-lg w-full"
        disabled={prepareOrder.data?.result == undefined}
        onClick={() => createOffer.mutate()}
      >
        Create Order
      </button>
    </div>
  );
};
