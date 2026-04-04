import { SegmentedControl } from "@kobalte/core/segmented-control";
import { Select } from "@kobalte/core/select";
import { FaSolidArrowsUpDown, FaSolidCheck } from "solid-icons/fa";
import { type Accessor, type Component, createSignal, For } from "solid-js";

import eth from "./assets/eth.svg";
import xmr from "./assets/xmr.svg";

const tokens = {
  xmr: {
    name: "XMR",
    icon: xmr,
  },
  eth: {
    name: "ETH",
    icon: eth,
  },
};

const TokenSelector: Component<{ token: Accessor<string>; setToken: (value: string) => void; }> = ({ token, setToken }) => (
  <Select
    options={Object.keys(tokens) as Array<keyof typeof tokens>}
    itemComponent={props => (
      <Select.Item item={props.item} class="flex items-center justify-between py-1 px-2">
        <Select.ItemLabel class="flex items-center gap-1">
          <img src={tokens[props.item.rawValue as keyof typeof tokens].icon} alt={tokens[props.item.rawValue as keyof typeof tokens].name} class="w-4 h-4" />
          <span class="text-sm">{tokens[props.item.rawValue as keyof typeof tokens].name}</span>
        </Select.ItemLabel>
        <Select.ItemIndicator class="select__item-indicator">
          <FaSolidCheck class="w-4 h-4" />
        </Select.ItemIndicator>
      </Select.Item>
    )}
    value={token()}
    onChange={value => value && setToken(value)}
  >
    <Select.Trigger class="flex items-center gap-1 hover:bg-(--thorin-background-secondary) rounded-md py-1 px-2 cursor-pointer">
      <Select.Value>
        {state => (
          <div class="flex items-center gap-1">
            <img src={tokens[state.selectedOption() as keyof typeof tokens].icon} alt={tokens[state.selectedOption() as keyof typeof tokens].name} class="w-4 h-4" />
            <span class="text-sm">{tokens[state.selectedOption() as keyof typeof tokens].name}</span>
          </div>
        )}
      </Select.Value>
      {/* <Select.Icon>
          xy
        </Select.Icon> */}
    </Select.Trigger>
    <Select.Portal>
      <Select.Content class="card p-0.5">
        <Select.Listbox class="select__listbox" />
      </Select.Content>
    </Select.Portal>
  </Select>
);

export const Swap = () => {
  console.log("placeholder");
  const [fromToken, setFromToken] = createSignal<string>("xmr");
  const [toToken, setToToken] = createSignal<string>("eth");

  return (
    <div class="card p-4 space-y-2">
      <div>
        <div class="flex justify-between items-center gap-1">
          <label for="input_amount" class="text-md py-1 flex justify-between items-center gap-1">
            <span>Sell</span>
          </label>
          <TokenSelector token={fromToken} setToken={setFromToken} />
        </div>
        <input placeholder="0" class="input w-full" id="input_amount" />
      </div>

      <div>
        <button
          class="btn aspect-square p-2 group"
          onClick={() => {
            const temp = fromToken();

            setFromToken(toToken());
            setToToken(temp);
          }}
        >
          <FaSolidArrowsUpDown class="group-hover:rotate-180 transition-all" />
        </button>
      </div>

      <div>
        <div class="flex justify-between items-center gap-1">
          <label for="output_amount" class="text-md py-1 gap-1">
            <span>Buy</span>
          </label>
          <TokenSelector token={toToken} setToken={setToToken} />
        </div>
        <input placeholder="0" class="input w-full" id="output_amount" />
      </div>
      <div>
        <SegmentedControl class="flex justify-between gap-2" defaultValue="1">
          <SegmentedControl.Label class="segmented-control__label">
            Slippage
          </SegmentedControl.Label>
          <div class="w-fit border border-(--thorin-border) rounded-md relative overflow-hidden" role="presentation">
            <SegmentedControl.Indicator class="absolute bottom-0 h-1 bg-(--thorin-blue-primary) transition-all not-last:-ml-px" />
            <div class="inline-flex flex-row divide-x divide-(--thorin-border)" role="presentation">
              <For each={["3%", "5%", "10%"]}>
                {slippage => (
                  <SegmentedControl.Item value={slippage} class="relative px-2">
                    <SegmentedControl.ItemInput class="" />
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
      <button class="btn-primary btn-lg w-full" disabled>
        Create Order
      </button>
    </div>
  );
};
