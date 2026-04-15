import { useConnection } from "@wagmi/solid";
import { Tabs } from "@kobalte/core/tabs";
import { CgSpinner } from "solid-icons/cg";
import { type Component, createMemo, createSignal, Show } from "solid-js";

import { type Offer, useOffers } from "../hooks/useOffers";
import { OrderDetailModal } from "./OrderDetailModal";
import { OrdersTabContent } from "./OrdersTabContent";

const isPast = (offer: Offer) => offer.state == 3 || offer.state == 4 || offer.state == 6;

const isUserInvolved = (offer: Offer, userAddress: string | undefined): boolean => {
  if (!userAddress) return false;
  const addr = userAddress.toLowerCase();
  return offer.owner.toLowerCase() === addr || offer.counterparty.toLowerCase() === addr;
};

export const OrderTable: Component = () => {
  const connection = useConnection();
  const [selectedOfferId, setSelectedOfferId] = createSignal<bigint | null>(null);
  const [activeTab, setActiveTab] = createSignal("open");
  const query = useOffers();

  const allOffers = createMemo(() =>
    (query.data?.pages.flatMap(page => page.offers) ?? []) as Offer[],
  );

  const userAddress = () => connection().address;

  return (
    <>
      <Tabs aria-label="Orders" value={activeTab()} onChange={setActiveTab} class="relative flex flex-col">
        <div class="px-2 flex flex-col gap-3 md:flex-row md:justify-between md:items-end">
          <div class="space-y-2">
            <Tabs.List class="relative flex items-center">
              {[
                ["open", "Open orders"],
                ["history", "Past orders"],
              ].map(([value, label]) => (
                <Tabs.Trigger value={value} class="data-selected:font-bold cursor-pointer px-2 py-1">
                  {label}
                </Tabs.Trigger>
              ))}
              <Tabs.Indicator class="h-1.5 bg-(--thorin-background-primary) absolute bottom-0 transition-all rounded-t-sm opacity-100 border border-(--thorin-border)" />
            </Tabs.List>
          </div>
          <div class="flex items-center gap-2 md:items-end">
            <Show when={query.isLoading || (query.isFetching && !query.isFetchingNextPage)}>
              <CgSpinner class="animate-spin shrink-0" />
            </Show>
          </div>
        </div>
        <OrdersTabContent
          allOffers={allOffers}
          tabValue="open"
          emptyLabel="No open offers"
          filterOffer={offer => !isPast(offer)}
          isLoading={query.isLoading}
          isError={query.isError}
          isActive={activeTab() === "open"}
          hasNextPage={query.hasNextPage}
          isFetchingNextPage={query.isFetchingNextPage}
          fetchNextPage={query.fetchNextPage}
          onSelectOffer={setSelectedOfferId}
        />
        <OrdersTabContent
          allOffers={allOffers}
          tabValue="history"
          emptyLabel="No matching history yet"
          filterOffer={offer => isPast(offer) && isUserInvolved(offer, userAddress())}
          isLoading={query.isLoading}
          isError={query.isError}
          isActive={activeTab() === "history"}
          hasNextPage={query.hasNextPage}
          isFetchingNextPage={query.isFetchingNextPage}
          fetchNextPage={query.fetchNextPage}
          onSelectOffer={setSelectedOfferId}
        />
      </Tabs>

      <Show when={selectedOfferId()}>
        <OrderDetailModal offerId={selectedOfferId()!} onClose={() => setSelectedOfferId(null)} />
      </Show>
    </>
  );
};
