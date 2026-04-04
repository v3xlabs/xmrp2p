import { Tabs } from "@kobalte/core/tabs";

import { Navbar } from "./navbar";
import { OrderTable } from "./orders/OrderTable";
import { Swap } from "./swap";

export const App = () => (
  <div class="w-full max-w-7xl mx-auto space-y-4">
    <Navbar />
    <div class="flex gap-4">
      <section class="w-[400px] space-y-2">
        <h2 class="px-2">Create Offer</h2>
        <Swap />
      </section>
      <div class="space-y-2 grow">
        <section class="grow space-y-2">
          <Tabs aria-label="Orders" defaultValue="open" class="relative">
            <div class="px-2">
              <Tabs.List class="relative flex items-center">
                {
                  [
                    ["open", "Open orders"],
                    ["history", "Past orders"],
                  ].map(([value, label]) => (
                    <Tabs.Trigger value={value} class="data-selected:font-bold cursor-pointer px-2 py-1">
                      {label}
                    </Tabs.Trigger>
                  ))
                }
                <Tabs.Indicator class="h-1.5 bg-(--thorin-background-primary) absolute bottom-0 transition-all rounded-t-sm opacity-100 border border-(--thorin-border)" />
              </Tabs.List>
            </div>
            <div class="card p-2">
              <Tabs.Content value="open">
                <OrderTable orders={["1", "2", "3", "4", "5"]} />
              </Tabs.Content>
              <Tabs.Content value="history">
                <OrderTable orders={["1", "2", "3"]} />
              </Tabs.Content>
            </div>
          </Tabs>
        </section>
      </div>
    </div>
  </div>
);
