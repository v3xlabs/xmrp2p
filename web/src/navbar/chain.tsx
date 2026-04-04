/* eslint-disable @stylistic/indent */
/* eslint-disable no-restricted-syntax */
import { useChainId, useChains, useSwitchChain } from "@wagmi/solid";
import { For } from "solid-js";

export const ChainSelector = () => {
    const chains = useChains();
    const chain = useChainId();
    const switchChain = useSwitchChain();

    return (

        <div>
            <select
              value={chain()?.toString()}
              onChange={e => switchChain.mutate({ chainId: Number(e.target.value) })}
            >
                <For each={chains()}>
                    {chain => <option value={chain.id.toString()}>{chain.name}</option>}
                </For>
            </select>
        </div>
    );
};
