/* eslint-disable @stylistic/indent */
/* eslint-disable no-restricted-syntax */
import { Select } from "@kobalte/core/select";
import { useSwitchChain } from "@wagmi/solid";
import { FaSolidCheck, FaSolidChevronDown } from "solid-icons/fa";
import { type Accessor, createEffect, createMemo } from "solid-js";
import { anvil, hoodi, mainnet, sepolia } from "viem/chains";

import ethIcon from "../assets/eth_tint.svg?raw";
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

const ChainIcon = (props: { chainId: Accessor<number>; }) => {
    const color = () => chainIdToColor(props.chainId());

    return (
        <div class="w-5 h-5 flex justify-center items-center rounded-full">
            <div
              innerHTML={ethIcon}
              class="w-4 h-4 fill-current"
              style={{
                    color: color(),
                }}
            />
        </div>
    );
};

type Chain = {
    value: string;
    label: string;
    disabled: boolean;
};

type Category = {
    label: string;
    options: Chain[];
};

export const ChainSelector = () => {
    const switchChain = useSwitchChain();
    const { chainId, chains } = useApp();

    createEffect(() => {
        const chainIdent = chainId();

        if (!chains().some(chain => chain.id === chainIdent)) {
            switchChain.mutate({ chainId: chains()[0].id });
        }
    });

    const chainList = createMemo(() => chains().map(chain => ({
        value: chain.id.toString(),
        label: chain.name,
        disabled: false,
        category:
            chain.testnet ? "testnet" : (chain.id === mainnet.id ? "mainnet" : "devnet"),
    })));

    const categories = createMemo(() => [
        {
            label: "Mainnets",
            options: chainList().filter(chain => chain.category === "mainnet"),
        },
        {
            label: "Testnets",
            options: chainList().filter(chain => chain.category === "testnet"),
        },
        {
            label: "Devnets",
            options: chainList().filter(chain => chain.category === "devnet"),
        },
    ].filter(category => category.options.length > 0));

    const chain = createMemo(() => chainList().find(chain => chain.value === chainId()?.toString()));

    return (
        <div>
            <Select<Chain, Category>
              value={chain()}
              options={categories()}
              optionValue="value"
              optionTextValue="label"
              optionDisabled="disabled"
              optionGroupChildren="options"
              placeholder="Select a chain…"
              class="input"
              itemComponent={props => (
                    <Select.Item item={props.item} class="flex items-center gap-1 px-2 py-1 hover:bg-(--thorin-background-secondary) hover:cursor-pointer">
                        <ChainIcon chainId={() => Number(props.item.rawValue.value)} />
                        <Select.ItemLabel>{props.item.rawValue.label}</Select.ItemLabel>
                        <Select.ItemIndicator class="select__item-indicator">
                            <FaSolidCheck />
                        </Select.ItemIndicator>
                    </Select.Item>
                )}
              sectionComponent={props => (
                    <Select.Section class="px-2 font-medium">
                        {props.section.rawValue.label}
                    </Select.Section>
                )}
              onChange={value => value && switchChain.mutate({ chainId: Number(value.value) })}
            >
                <Select.Trigger class="flex items-center gap-2" aria-label="Chain">
                    <Select.Value<Chain> class="select__value">
                        {state => (
                            <span class="flex items-center gap-1">
                                <ChainIcon chainId={() => Number(state.selectedOption().value)} />
                                {state.selectedOption().label}
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
