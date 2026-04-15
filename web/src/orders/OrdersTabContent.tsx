import { Tabs } from "@kobalte/core/tabs";
import { type Accessor, type Component, createMemo, Show } from "solid-js";

import { type Offer } from "../hooks/useOffers";
import { OrdersDataTable, type OrdersDataTableProps } from "./OrdersDataTable";

type OrdersTabContentProps = Omit<OrdersDataTableProps, "offers" | "emptyLabel"> & {
  allOffers: Accessor<Offer[]>;
  tabValue: string;
  emptyLabel: string;
  isActive: boolean;
  filterOffer: (offer: Offer) => boolean;
};

export const OrdersTabContent: Component<OrdersTabContentProps> = (props) => {
  const offers = createMemo(() => props.allOffers().filter(props.filterOffer));

  return (
    <Tabs.Content value={props.tabValue} class="flex flex-col gap-2">
      <Show when={props.isActive}>
        <OrdersDataTable
          offers={offers}
          isLoading={props.isLoading}
          isError={props.isError}
          emptyLabel={props.emptyLabel}
          hasNextPage={props.hasNextPage}
          isFetchingNextPage={props.isFetchingNextPage}
          fetchNextPage={props.fetchNextPage}
          onSelectOffer={props.onSelectOffer}
        />
      </Show>
    </Tabs.Content>
  );
};
