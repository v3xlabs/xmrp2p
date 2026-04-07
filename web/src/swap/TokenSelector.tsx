import { Select } from "@kobalte/core/select";
import { FaSolidChevronDown } from "solid-icons/fa";
import { type Accessor, type Component } from "solid-js";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";

export const tokens: Record<string, { name: string; icon: string; }> = {
  xmr: { name: "XMR", icon: xmrIcon },
  eth: { name: "ETH", icon: ethIcon },
};

export const TokenSelector: Component<{
  token: Accessor<string>;
  setToken: (value: string) => void;
}> = ({ token, setToken }) => (
  <Select
    options={Object.keys(tokens)}
    itemComponent={props => (
      <Select.Item
        item={props.item}
        class="flex items-center justify-between py-1 px-2 hover:bg-(--thorin-background-secondary) hover:cursor-pointer"
      >
        <Select.ItemLabel class="flex items-center gap-1">
          <img
            src={tokens[props.item.rawValue]?.icon}
            alt={tokens[props.item.rawValue]?.name}
            class="w-4 h-4"
          />
          <span class="text-sm">
            {tokens[props.item.rawValue]?.name}
          </span>
        </Select.ItemLabel>
      </Select.Item>
    )}
    value={token()}
    onChange={value => value && setToken(value)}
  >
    <Select.Trigger class="flex items-center gap-1 hover:bg-(--thorin-background-secondary) rounded-md py-1 px-2 cursor-pointer">
      <Select.Value>
        {state => (
          <div class="flex items-center gap-1">
            <img
              src={tokens[state.selectedOption() as string]?.icon}
              alt={tokens[state.selectedOption() as string]?.name}
              class="w-4 h-4"
            />
            <span class="text-sm">
              {tokens[state.selectedOption() as string]?.name}
            </span>
          </div>
        )}
      </Select.Value>
      <Select.Icon>
        <FaSolidChevronDown class="w-2.5 h-2.5" />
      </Select.Icon>
    </Select.Trigger>
    <Select.Portal>
      <Select.Content class="card p-0.5">
        <Select.Listbox class="select__listbox" />
      </Select.Content>
    </Select.Portal>
  </Select>
);
