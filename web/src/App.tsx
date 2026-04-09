/* eslint-disable no-restricted-syntax */
import { useChainId, useSwitchChain } from "@wagmi/solid";
import { mainnet } from "@wagmi/solid/chains";
import { createEffect } from "solid-js";

import { useSettings } from "./context/SettingsContext";
import { Navbar } from "./navbar";
import { OrderTable } from "./orders/OrderTable";
import { SettingsButton } from "./settings";
import { Swap } from "./swap";

export const App = () => {
  const { availableChains } = useSettings();
  const chainId = useChainId();
  const switchChain = useSwitchChain();

  createEffect(() => {
    const chains = availableChains();
    const current = chainId();

    if (current && !chains.some(c => c.id === current)) {
      switchChain.mutate({ chainId: mainnet.id });
    }
  });

  return (
    <div class="w-full max-w-7xl mx-auto space-y-4">
      <Navbar />
      <div class="flex gap-4 flex-col lg:flex-row px-4">
        <section class="w-full lg:w-[400px] space-y-2">
          <div class="flex justify-between items-center">
            <h2 class="px-2">Create Offer</h2>
            <SettingsButton />
          </div>
          <Swap />
        </section>
        <div class="space-y-2 grow">
          <section class="grow space-y-2">
            <OrderTable />
          </section>
        </div>
      </div>
    </div>
  );
};
