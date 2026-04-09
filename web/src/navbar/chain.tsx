/* eslint-disable @stylistic/indent */
/* eslint-disable no-restricted-syntax */
import { Select } from "@kobalte/core/select";
import { useSwitchChain } from "@wagmi/solid";
import { FaSolidCheck, FaSolidChevronDown } from "solid-icons/fa";

import { useSettings } from "../context/SettingsContext";
import { useApp } from "../hooks/useApp";

export const ChainSelector = () => {
    const { availableChains } = useSettings();
    const switchChain = useSwitchChain();
    const { chainId } = useApp();

    return (
        <div>
            <Select
              value={chainId()?.toString()}
              options={availableChains().map(chain => chain.id)}
              placeholder="Select a chain…"
              class="input"
              itemComponent={(props) => {
                    const chain = availableChains().find(chain => chain.id === Number(props.item.rawValue));

                    return (
                        <Select.Item item={props.item} class="flex items-center gap-1">
                            <Select.ItemLabel>{chain?.name}</Select.ItemLabel>
                            <Select.ItemIndicator class="select__item-indicator">
                                <FaSolidCheck />
                            </Select.ItemIndicator>
                        </Select.Item>
                    );
                }}
              onChange={value => switchChain.mutate({ chainId: Number(value) })}
            >
                <Select.Trigger class="flex items-center gap-2" aria-label="Chain">
                    <Select.Value class="select__value">
                        {state => availableChains().find(chain => chain.id === Number(state.selectedOption()))?.name}
                    </Select.Value>
                    <Select.Icon class="select__icon">
                        <FaSolidChevronDown class="w-2.5 h-2.5" />
                    </Select.Icon>
                </Select.Trigger>
                <Select.Portal>
                    <Select.Content class="card p-0.5" style={{ "transform-origin": "var(--kb-select-content-transform-origin)" }}>
                        <Select.Listbox class="select__listbox" />
                    </Select.Content>
                </Select.Portal>
            </Select>
        </div>
    );
};
