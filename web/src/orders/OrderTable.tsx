import { Tabs } from "@kobalte/core/tabs";
import { useConnection } from "@wagmi/solid";
import { CgSpinner } from "solid-icons/cg";
import { type Component, createEffect, createMemo, createSignal, Show } from "solid-js";

import { type Offer, useOffers } from "../hooks/useOffers";
import { OrderDetailModal } from "./OrderDetailModal";
import { OrdersDataTable } from "./OrdersDataTable";

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
  const openOffers = createMemo(() => allOffers().filter(offer => !isPast(offer)));
  const historyOffers = createMemo(() =>
    allOffers().filter(offer => isPast(offer) && isUserInvolved(offer, connection().address)),
  );
  const shouldAutoSearchHistory = createMemo(() => (
    activeTab() === "history"
    && !!connection().address
    && historyOffers().length === 0
    && query.hasNextPage
  ));
  const historyHasNextPage = createMemo(() => (
    !!connection().address
    && query.hasNextPage
    && historyOffers().length > 0
  ));
  const historyEmptyLabel = createMemo(() => {
    if (!connection().address) {
      return "Connect your wallet to view past orders";
    }

    if (shouldAutoSearchHistory() || query.isFetchingNextPage) {
      return "Searching past orders...";
    }

    return "No past orders for this wallet";
  });

  createEffect(() => {
    if (!shouldAutoSearchHistory()) return;

    if (query.isLoading || query.isError || query.isFetchingNextPage) return;

    void query.fetchNextPage();
  });

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
        <Tabs.Content value="open" class="flex flex-col gap-2">
          <Show when={activeTab() === "open"}>
            <OrdersDataTable
              emptyLabel="No open offers"
              loadMoreLabel="Load more offers"
              offers={openOffers}
              isLoading={query.isLoading}
              isError={query.isError}
              hasNextPage={query.hasNextPage}
              isFetchingNextPage={query.isFetchingNextPage}
              fetchNextPage={query.fetchNextPage}
              onSelectOffer={setSelectedOfferId}
            />
          </Show>
        </Tabs.Content>
        <Tabs.Content value="history" class="flex flex-col gap-2">
          <Show when={activeTab() === "history"}>
            <OrdersDataTable
              emptyLabel={historyEmptyLabel()}
              loadMoreLabel="Search older offers"
              offers={historyOffers}
              isLoading={query.isLoading}
              isError={query.isError}
              hasNextPage={historyHasNextPage()}
              isFetchingNextPage={query.isFetchingNextPage}
              fetchNextPage={query.fetchNextPage}
              onSelectOffer={setSelectedOfferId}
            />
          </Show>
        </Tabs.Content>
      </Tabs>

      <Show when={selectedOfferId()}>
        <OrderDetailModal offerId={selectedOfferId()!} onClose={() => setSelectedOfferId(null)} />
      </Show>
    </>
  );
};
