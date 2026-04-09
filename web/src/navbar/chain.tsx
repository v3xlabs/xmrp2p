/* eslint-disable @stylistic/indent */
/* eslint-disable no-restricted-syntax */
import { Select } from "@kobalte/core/select";
import { useChains, useSwitchChain } from "@wagmi/solid";
import { FaSolidCheck, FaSolidChevronDown } from "solid-icons/fa";
import { createMemo } from "solid-js";
import { anvil, hoodi, mainnet, sepolia } from "viem/chains";

import ethIcon from "../assets/eth_tint.svg?raw";
import { useSettings } from "../context/SettingsContext";
import { useApp } from "../hooks/useApp";

const chainIdToColor = (chainId: number) => {
    switch (chainId) {
        case mainnet.id: {
            // blue
            return "rgba(0,0,255,0.5)";
        }
        case anvil.id: {
            // purple
            return "rgba(128,0,128,0.5)";
        }
        case sepolia.id: {
            // hotpink
            return "rgba(255,105,180,0.5)";
        }
        case hoodi.id: {
            // green
            return "rgba(0,128,0,0.5)";
        }
    }
};

const ChainIcon = (props: { chainId: number; }) => {
    const color = chainIdToColor(props.chainId);

    return (
        <div class="w-5 h-5 flex justify-center items-center rounded-full">
            <div
              innerHTML={ethIcon}
              class="w-4 h-4 fill-current"
              style={{
                    color,
                }}
            />
        </div>
    );
};

export const ChainSelector = () => {
    const { modes } = useSettings();
    const switchChain = useSwitchChain();
    const { chainId } = useApp();
    const chains = useChains();

    const availableChains = createMemo(() => chains().filter((chain) => {
        if (modes.devnets && chain.id === anvil.id) return true;

        if (modes.testnets && chain.id === sepolia.id) return true;

        if (modes.mainnets && chain.id === mainnet.id) return true;

        return false;
    }));

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
                        <Select.Item item={props.item} class="flex items-center gap-1 px-2 py-1 hover:bg-(--thorin-background-secondary) hover:cursor-pointer">
                            <ChainIcon chainId={Number(props.item.rawValue)} />
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
                        {state => (
                            <span class="flex items-center gap-1">
                                <ChainIcon chainId={Number(state.selectedOption())} />
                                {availableChains().find(chain => chain.id === Number(state.selectedOption()))?.name}
                            </span>
                        )}
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
