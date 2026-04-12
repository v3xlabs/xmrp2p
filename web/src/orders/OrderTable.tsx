import { Tabs } from "@kobalte/core/tabs";
import {
  createColumnHelper,
  createSolidTable,
  flexRender,
  getCoreRowModel,
} from "@tanstack/solid-table";
import { createVirtualizer } from "@tanstack/solid-virtual";
import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import { type Accessor, type Component, createEffect, createMemo, createSignal, For, Show } from "solid-js";
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
const ROW_HEIGHT = 76;
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
  onSelectOffer: (offerId: bigint) => void;
};

const Table: Component<TableProps> = (props) => {
  let scrollElement: HTMLDivElement | undefined;

  const table = createSolidTable({
    columns,
    get data() {
      return props.offers();
    },
    getCoreRowModel: getCoreRowModel(),
    getRowId: row => row.id.toString(),
  });

  const tableRows = createMemo(() => table.getRowModel().rows);
  const rowVirtualizer = createVirtualizer<HTMLDivElement, HTMLDivElement>({
    get count() {
      return tableRows().length;
    },
    getScrollElement: () => scrollElement ?? null,
    estimateSize: () => ROW_HEIGHT,
    overscan: 12,
  });
  const virtualRows = createMemo(() => rowVirtualizer.getVirtualItems());
  const paddingTop = createMemo(() => (virtualRows().length > 0 ? virtualRows()[0]!.start : 0));
  const paddingBottom = createMemo(() => {
    const items = virtualRows();

    if (items.length === 0) return 0;

    return rowVirtualizer.getTotalSize() - items[items.length - 1]!.end;
  });

  createEffect(() => {
    tableRows().length;
    queueMicrotask(() => {
      rowVirtualizer.scrollToOffset(0);
      rowVirtualizer.measure();
    });
  });

  return (
    <div class="card flex h-[70vh] min-h-[32rem] flex-col p-2 xl:h-full xl:min-h-0">
      <div
        ref={element => {
          scrollElement = element;
        }}
        class="min-h-0 flex-1 overflow-auto"
      >
        <div class="min-w-[980px]">
          <div class="sticky top-0 z-10 bg-(--thorin-background-primary)">
            <For each={table.getHeaderGroups()}>
              {headerGroup => (
                <div class="grid border-b border-(--thorin-border)" style={{ "grid-template-columns": TABLE_GRID_COLUMNS }}>
                  <For each={headerGroup.headers}>
                    {header => {
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
            <Show when={paddingTop() > 0}>
              <div style={{ height: `${paddingTop()}px` }} />
            </Show>
            <For each={virtualRows()}>
              {virtualRow => {
                const row = () => tableRows()[virtualRow.index];

                return (
                  <div
                    class="grid cursor-pointer transition-colors hover:bg-(--thorin-background-secondary)"
                    style={{ "grid-template-columns": TABLE_GRID_COLUMNS }}
                    onClick={() => row() && props.onSelectOffer(row()!.original.id)}
                  >
                    <For each={row()?.getVisibleCells() ?? []}>
                      {cell => (
                        <div class="px-3 py-2.5 text-sm flex items-center min-h-[76px]">
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </div>
                      )}
                    </For>
                  </div>
                );
              }}
            </For>
            <Show when={paddingBottom() > 0}>
              <div style={{ height: `${paddingBottom()}px` }} />
            </Show>
          </Show>
        </div>
      </div>
    </div>
  );
};

export const OrderTable: Component = () => {
  const [selectedOfferId, setSelectedOfferId] = createSignal<bigint | null>(null);
  const query = useOffers(selectedOfferId);

  const allOffers = createMemo(() =>
    ((query.data?.pages.flat() ?? []) as Offer[]).filter(offer => offer.state !== 0),
  );

  const openOffers = createMemo(() => allOffers().filter(offer => !isPast(offer)));
  const pastOffers = createMemo(() => allOffers().filter(isPast));

  return (
    <>
      <Tabs aria-label="Orders" defaultValue="open" class="relative h-full">
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
            <Show when={query.isLoading || query.isFetching}>
              <CgSpinner class="animate-spin shrink-0" />
            </Show>
          </div>
        </div>
        <Tabs.Content value="open" class="h-full space-y-2">
          <Table
            offers={openOffers}
            isLoading={query.isLoading}
            isError={query.isError}
            emptyLabel="No open offers"
            onSelectOffer={setSelectedOfferId}
          />
          <Show when={query.hasNextPage}>
            <button class="btn px-3 py-2" onClick={() => query.fetchNextPage()}>
              Load more
            </button>
          </Show>
        </Tabs.Content>
        <Tabs.Content value="history" class="h-full space-y-2">
          <Table
            offers={pastOffers}
            isLoading={query.isLoading}
            isError={query.isError}
            emptyLabel="No matching history yet"
            onSelectOffer={setSelectedOfferId}
          />
          <Show when={query.hasNextPage}>
            <button class="btn px-3 py-2" onClick={() => query.fetchNextPage()}>
              Load more
            </button>
          </Show>
        </Tabs.Content>
      </Tabs>

      <Show when={selectedOfferId()}>
        <OrderDetailModal offerId={selectedOfferId()!} onClose={() => setSelectedOfferId(null)} />
      </Show>
    </>
  );
};
