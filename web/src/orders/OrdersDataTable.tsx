/* eslint-disable no-restricted-syntax */
import {
  createSolidTable,
  flexRender,
  getCoreRowModel,
} from "@tanstack/solid-table";
import { createVirtualizer } from "@tanstack/solid-virtual";
import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import {
  type Accessor,
  type Component,
  createEffect,
  createMemo,
  createSignal,
  For,
  Show,
} from "solid-js";
import { match } from "ts-pattern";

import { type Offer } from "../hooks/useOffers";
import { orderTableColumns, TABLE_GRID_COLUMNS } from "./OrderTableColumns";
import { OrderTableMobileCard } from "./OrderTableMobileCard";

export type OrdersDataTableProps = {
  offers: Accessor<Offer[]>;
  isLoading: boolean;
  isError: boolean;
  emptyLabel: string;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => Promise<unknown>;
  onSelectOffer: (offerId: bigint) => void;
};

export const OrdersDataTable: Component<OrdersDataTableProps> = (props) => {
  const [scrollElement, setScrollElement] = createSignal<HTMLDivElement | null>(null);

  const table = createSolidTable({
    columns: orderTableColumns,
    get data() {
      return props.offers();
    },
    getCoreRowModel: getCoreRowModel(),
    getRowId: row => row.id.toString(),
  });

  const tableRows = createMemo(() => table.getRowModel().rows);
  const virtualCount = createMemo(() => {
    const rowCount = tableRows().length;

    return props.hasNextPage ? rowCount + 1 : rowCount;
  });

  const rowVirtualizer = createVirtualizer<HTMLDivElement, HTMLDivElement>({
    get count() {
      return virtualCount();
    },
    getScrollElement: () => scrollElement(),
    initialRect: {
      height: 900,
      width: 700,
    },
    estimateSize: () => 76,
    overscan: 8,
  });

  createEffect(() => {
    const element = scrollElement();
    const rowCount = tableRows().length;

    if (!element || rowCount === 0) {
      return;
    }

    queueMicrotask(() => {
      rowVirtualizer.measure();
    });
  });

  createEffect(() => {
    const rowCount = tableRows().length;
    const virtualItems = rowVirtualizer.getVirtualItems();
    const lastItem = virtualItems[virtualItems.length - 1];

    if (!lastItem || rowCount === 0) {
      return;
    }

    if (lastItem.index >= rowCount - 1 && props.hasNextPage && !props.isFetchingNextPage) {
      void props.fetchNextPage();
    }
  });

  return (
    <div class="card flex min-h-[32rem] flex-col p-2">
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
        <div class="space-y-3 md:hidden">
          <For each={props.offers()}>
            {offer => <OrderTableMobileCard offer={offer} onSelectOffer={props.onSelectOffer} />}
          </For>
          <Show when={props.hasNextPage}>
            <button
              type="button"
              class="btn flex w-full items-center justify-center gap-2 px-4 py-3 text-sm"
              onClick={() => void props.fetchNextPage()}
            >
              <Show when={props.isFetchingNextPage} fallback={<span>Load more offers</span>}>
                <>
                  <CgSpinner class="shrink-0 animate-spin" />
                  Loading more...
                </>
              </Show>
            </button>
          </Show>
        </div>

        <div ref={setScrollElement} class="hidden h-[68vh] overflow-auto md:block">
          <div class="min-w-[860px]">
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
            <div
              class="relative w-full"
              style={{ height: `${rowVirtualizer.getTotalSize()}px` }}
            >
              <For each={rowVirtualizer.getVirtualItems()}>
                {(virtualRow) => {
                  const row = createMemo(() => tableRows()[virtualRow.index]);
                  const isLoaderRow = createMemo(() => virtualRow.index >= tableRows().length);

                  return (
                    <div
                      class="absolute left-0 top-0 w-full"
                      style={{
                        height: `${virtualRow.size}px`,
                        transform: `translateY(${virtualRow.start}px)`,
                      }}
                    >
                      <Show
                        when={!isLoaderRow() && row()}
                        fallback={(
                          <div class="flex min-h-[76px] items-center justify-center px-3 py-2.5 text-sm text-(--thorin-text-secondary)">
                            <Show when={props.isFetchingNextPage} fallback={<span>Scroll to load more</span>}>
                              <span class="inline-flex items-center gap-2">
                                <CgSpinner class="animate-spin shrink-0" />
                                Loading more...
                              </span>
                            </Show>
                          </div>
                        )}
                      >
                        <div
                          class="grid cursor-pointer transition-colors hover:bg-(--thorin-background-secondary)"
                          style={{ "grid-template-columns": TABLE_GRID_COLUMNS }}
                          onClick={() => props.onSelectOffer(row()!.original.id)}
                        >
                          <For each={row()!.getVisibleCells()}>
                            {cell => (
                              <div class="flex min-h-[76px] items-center px-3 py-2.5 text-sm">
                                {flexRender(cell.column.columnDef.cell, cell.getContext())}
                              </div>
                            )}
                          </For>
                        </div>
                      </Show>
                    </div>
                  );
                }}
              </For>
            </div>
          </div>
        </div>
      </Show>
    </div>
  );
};
