/* eslint-disable no-restricted-syntax */
import { Tabs } from "@kobalte/core/tabs";
import {
  createColumnHelper,
  createSolidTable,
  flexRender,
  getCoreRowModel,
} from "@tanstack/solid-table";
import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import { type Accessor, type Component, createEffect, createMemo, createSignal, For, onCleanup, Show } from "solid-js";
import { match } from "ts-pattern";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import { type Offer, useOffers } from "../hooks/useOffers";
import { Price } from "../swap/price";
import { Addr } from "../utils/address";
import { OrderDetailModal } from "./OrderDetailModal";
import { StatusBadge } from "./StatusBadge";

const columnHelper = createColumnHelper<Offer>();
const TABLE_GRID_COLUMNS = "minmax(72px,0.7fr) minmax(150px,1.2fr) minmax(170px,1.35fr) minmax(132px,0.95fr) minmax(132px,0.95fr) minmax(132px,0.95fr) minmax(96px,0.8fr)";

const columns = [
  columnHelper.accessor("kind", {
    header: "Side",
    cell: ({ row }) => {
      const isBuy = row.original.kind === 1;

      return (
        <span
          class={classnames(
            "font-medium text-sm",
            isBuy
              ? "text-(--thorin-green-primary)"
              : "text-(--thorin-red-primary)",
          )}
        >
          {isBuy ? "Buy" : "Sell"}
        </span>
      );
    },
  }),
  columnHelper.accessor("owner", {
    header: "Owner",
    cell: ({ row }) => (
      <div class="text-left tabular-nums">
        <Addr address={row.original.owner} />
      </div>
    ),
  }),
  columnHelper.accessor("counterparty", {
    header: "Counterparty",
    cell: ({ row }) => (
      <div class="text-left tabular-nums">
        <Addr address={row.original.counterparty} />
      </div>
    ),
  }),
  columnHelper.accessor("price", {
    header: () => <div class="text-right">Rate</div>,
    cell: ({ row }) => (
      <div class="text-right tabular-nums text-(--thorin-text-secondary) text-sm wrap-normal">
        <div>{formatUnits(row.original.price, 12)}</div>
        <span class="ml-1 text-xs opacity-60">XMR/ETH</span>
      </div>
    ),
  }),
  columnHelper.display({
    id: "eth_amount",
    header: () => (
      <div class="flex items-center gap-1 justify-end">
        <img src={ethIcon} alt="ETH" class="w-4 h-4" />
        <span>ETH</span>
      </div>
    ),
    cell: ({ row }) => (
      <div class="text-end tabular-nums">
        <div class="font-medium">{formatEther(row.original.amount)}</div>
        <Price token={() => "eth"} amount={() => row.original.amount} />
      </div>
    ),
  }),
  columnHelper.display({
    id: "xmr_amount",
    header: () => (
      <div class="flex items-center gap-1 justify-end">
        <img src={xmrIcon} alt="XMR" class="w-4 h-4" />
        <span>XMR</span>
      </div>
    ),
    cell: ({ row }) => {
      const xmrAmountValue = row.original.amount * row.original.price / 10n ** 18n;
      const xmrAmount = formatUnits(xmrAmountValue, 12);

      return (
        <div class="text-right tabular-nums">
          <div class="font-medium">{xmrAmount}</div>
          <div>
            <Price token={() => "xmr"} amount={() => xmrAmountValue} />
          </div>
        </div>
      );
    },
  }),
  columnHelper.accessor("state", {
    header: () => <div class="text-right">Status</div>,
    cell: ({ row }) => (
      <div class="flex justify-end">
        <StatusBadge state={row.original.state} />
      </div>
    ),
  }),
];

const isPast = (offer: Offer) => offer.state == 3 || offer.state == 4 || offer.state == 6;

type TableProps = {
  offers: Accessor<Offer[]>;
  isLoading: boolean;
  isError: boolean;
  emptyLabel: string;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => Promise<unknown>;
  onSelectOffer: (offerId: bigint) => void;
};

const Table: Component<TableProps> = (props) => {
  let loadMoreElement: HTMLDivElement | undefined;

  const table = createSolidTable({
    columns,
    get data() {
      return props.offers();
    },
    getCoreRowModel: getCoreRowModel(),
    getRowId: row => row.id.toString(),
  });

  const tableRows = createMemo(() => table.getRowModel().rows);

  createEffect(() => {
    const element = loadMoreElement;

    if (!element) {
      return;
    }

    const observer = new IntersectionObserver((entries) => {
      const entry = entries[0];

      if (entry?.isIntersecting && props.hasNextPage && !props.isFetchingNextPage) {
        void props.fetchNextPage();
      }
    }, { rootMargin: "400px 0px" });

    observer.observe(element);

    onCleanup(() => {
      observer.disconnect();
    });
  });

  return (
    <div class="card flex min-h-[32rem] flex-col p-2">
      <div class="min-w-[980px]">
        <div class="sticky top-0 z-10 bg-(--thorin-background-primary)">
          <For each={table.getHeaderGroups()}>
            {headerGroup => (
              <div class="grid border-b border-(--thorin-border)" style={{ "grid-template-columns": TABLE_GRID_COLUMNS }}>
                <For each={headerGroup.headers}>
                  {(header) => {
                    const isRightAligned = ["price", "eth_amount", "xmr_amount", "state"].includes(header.column.id);

                    return (
                      <div class="px-3 py-2 text-left text-xs font-medium text-(--thorin-text-secondary) uppercase tracking-wider">
                        <div class={classnames("w-full", isRightAligned ? "text-right" : "text-left")}>
                          {header.isPlaceholder
                            ? null
                            : flexRender(header.column.columnDef.header, header.getContext())}
                        </div>
                      </div>
                    );
                  }}
                </For>
              </div>
            )}
          </For>
        </div>
        <Show
          when={tableRows().length > 0}
          fallback={(
            <div class="py-8 text-center text-(--thorin-text-secondary) text-sm">
              {match(props)
                .when(q => q.isLoading, () => "Loading offers...")
                .when(q => q.isError, () => "Failed to load offers")
                .otherwise(() => props.emptyLabel)}
            </div>
          )}
        >
          <For each={tableRows()}>
            {row => (
              <div
                class="grid cursor-pointer transition-colors hover:bg-(--thorin-background-secondary)"
                style={{ "grid-template-columns": TABLE_GRID_COLUMNS }}
                onClick={() => props.onSelectOffer(row.original.id)}
              >
                <For each={row.getVisibleCells()}>
                  {cell => (
                    <div class="px-3 py-2.5 text-sm flex items-center min-h-[76px]">
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </div>
                  )}
                </For>
              </div>
            )}
          </For>
        </Show>
        <Show when={props.hasNextPage || props.isFetchingNextPage}>
          <div ref={loadMoreElement} class="flex justify-center py-3 text-sm text-(--thorin-text-secondary)">
            <Show when={props.isFetchingNextPage} fallback={<span>Scroll to load more</span>}>
              <span class="inline-flex items-center gap-2">
                <CgSpinner class="animate-spin shrink-0" />
                Loading more...
              </span>
            </Show>
          </div>
        </Show>
      </div>
    </div>
  );
};

type OrdersTabContentProps = {
  allOffers: Accessor<Offer[]>;
  isLoading: boolean;
  isError: boolean;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => Promise<unknown>;
  onSelectOffer: (offerId: bigint) => void;
};

const OpenOrdersTab: Component<OrdersTabContentProps> = (props) => {
  const offers = createMemo(() => props.allOffers().filter(offer => !isPast(offer)));

  return (
    <Tabs.Content value="open" class="flex flex-col gap-2">
      <Table
        offers={offers}
        isLoading={props.isLoading}
        isError={props.isError}
        emptyLabel="No open offers"
        hasNextPage={props.hasNextPage}
        isFetchingNextPage={props.isFetchingNextPage}
        fetchNextPage={props.fetchNextPage}
        onSelectOffer={props.onSelectOffer}
      />
    </Tabs.Content>
  );
};

const PastOrdersTab: Component<OrdersTabContentProps> = (props) => {
  const offers = createMemo(() => props.allOffers().filter(isPast));

  return (
    <Tabs.Content value="history" class="flex flex-col gap-2">
      <Table
        offers={offers}
        isLoading={props.isLoading}
        isError={props.isError}
        emptyLabel="No matching history yet"
        hasNextPage={props.hasNextPage}
        isFetchingNextPage={props.isFetchingNextPage}
        fetchNextPage={props.fetchNextPage}
        onSelectOffer={props.onSelectOffer}
      />
    </Tabs.Content>
  );
};

export const OrderTable: Component = () => {
  const [selectedOfferId, setSelectedOfferId] = createSignal<bigint | null>(null);
  const query = useOffers();

  const allOffers = createMemo(() =>
    (query.data?.pages.flatMap(page => page.offers) ?? []) as Offer[],
  );

  return (
    <>
      <Tabs aria-label="Orders" defaultValue="open" class="relative flex flex-col">
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
        <OpenOrdersTab
          allOffers={allOffers}
          isLoading={query.isLoading}
          isError={query.isError}
          hasNextPage={query.hasNextPage}
          isFetchingNextPage={query.isFetchingNextPage}
          fetchNextPage={query.fetchNextPage}
          onSelectOffer={setSelectedOfferId}
        />
        <PastOrdersTab
          allOffers={allOffers}
          isLoading={query.isLoading}
          isError={query.isError}
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
