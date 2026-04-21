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
import { orderTableColumns } from "./OrderTableColumns";
import { OrderTableMobileCard } from "./OrderTableMobileCard";

const RIGHT_ALIGNED_COLUMN_IDS = new Set(["price", "eth_amount", "xmr_amount", "state"]);

export type OrdersDataTableProps = {
  offers: Accessor<Offer[]>;
  isLoading: boolean;
  isError: boolean;
  emptyLabel: string;
  loadMoreLabel: string;
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage: () => Promise<unknown>;
  onSelectOffer: (offerId: bigint) => void;
};

export const OrdersDataTable: Component<OrdersDataTableProps> = (props) => {
  const [scrollElement, setScrollElement] = createSignal<HTMLDivElement | null>(null);
  const canLoadMore = () => props.hasNextPage && !props.isLoading && !props.isError;

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

  const rowVirtualizer = createVirtualizer<HTMLDivElement, HTMLTableRowElement>({
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
          <div class="flex min-h-[28rem] flex-1 flex-col items-center justify-center gap-4 px-4 py-8 text-center text-(--thorin-text-secondary) text-sm xl:min-h-[68vh]">
            <div>
              {match(props)
                .when(q => q.isLoading, () => "Loading offers...")
                .when(q => q.isError, () => "Failed to load offers")
                .otherwise(() => props.emptyLabel)}
            </div>
            <Show when={canLoadMore()}>
              <button
                type="button"
                class="btn flex items-center justify-center gap-2 px-4 py-3 text-sm"
                onClick={() => void props.fetchNextPage()}
              >
                <Show when={props.isFetchingNextPage} fallback={<span>{props.loadMoreLabel}</span>}>
                  <>
                    <CgSpinner class="shrink-0 animate-spin" />
                    Loading more...
                  </>
                </Show>
              </button>
            </Show>
          </div>
        )}
      >
        <div class="space-y-3 xl:hidden">
          <For each={props.offers()}>
            {offer => <OrderTableMobileCard offer={offer} onSelectOffer={props.onSelectOffer} />}
          </For>
          <Show when={props.hasNextPage}>
            <button
              type="button"
              class="btn flex w-full items-center justify-center gap-2 px-4 py-3 text-sm"
              onClick={() => void props.fetchNextPage()}
            >
              <Show when={props.isFetchingNextPage} fallback={<span>{props.loadMoreLabel}</span>}>
                <>
                  <CgSpinner class="shrink-0 animate-spin" />
                  Loading more...
                </>
              </Show>
            </button>
          </Show>
        </div>

        <div
          ref={setScrollElement}
          class="relative hidden h-[68vh] overflow-auto xl:block"
          style={{ "scrollbar-gutter": "stable" }}
        >
          <table
            class="border-collapse"
            style={{
              "display": "grid",
              "width": `${table.getTotalSize()}px`,
              "min-width": "100%",
            }}
          >
            <thead
              class="bg-(--thorin-background-primary)"
              style={{
                "display": "grid",
                "position": "sticky",
                "top": "0",
                "z-index": "10",
              }}
            >
              <For each={table.getHeaderGroups()}>
                {headerGroup => (
                  <tr class="flex w-full border-b border-(--thorin-border)">
                    <For each={headerGroup.headers}>
                      {(header) => {
                        const isRightAligned = RIGHT_ALIGNED_COLUMN_IDS.has(header.column.id);

                        return (
                          <th
                            class="min-w-0 px-3 py-2 text-left text-xs font-medium text-(--thorin-text-secondary) uppercase tracking-wider"
                            style={{
                              display: "flex",
                              width: `${header.getSize()}px`,
                            }}
                          >
                            <div class={classnames("w-full", isRightAligned ? "text-right" : "text-left")}>
                              {header.isPlaceholder
                                ? null
                                : flexRender(header.column.columnDef.header, header.getContext())}
                            </div>
                          </th>
                        );
                      }}
                    </For>
                  </tr>
                )}
              </For>
            </thead>
            <tbody
              style={{
                display: "grid",
                height: `${rowVirtualizer.getTotalSize()}px`,
                position: "relative",
              }}
            >
              <For each={rowVirtualizer.getVirtualItems()}>
                {(virtualRow) => {
                  const row = createMemo(() => tableRows()[virtualRow.index]);
                  const isLoaderRow = createMemo(() => virtualRow.index >= tableRows().length);

                  return (
                    <tr
                      class={classnames(
                        "absolute left-0 top-0 w-full",
                        !isLoaderRow() && row() && "cursor-pointer transition-colors hover:bg-(--thorin-background-secondary)",
                      )}
                      style={{
                        display: "flex",
                        height: `${virtualRow.size}px`,
                        transform: `translateY(${virtualRow.start}px)`,
                      }}
                      onClick={() => {
                        if (row() && !isLoaderRow()) {
                          props.onSelectOffer(row()!.original.id);
                        }
                      }}
                    >
                      <Show
                        when={!isLoaderRow() && row()}
                        fallback={(
                          <td
                            colSpan={table.getVisibleLeafColumns().length}
                            class="flex min-h-[76px] items-center justify-center px-3 py-2.5 text-sm text-(--thorin-text-secondary)"
                            style={{ width: `${table.getTotalSize()}px` }}
                          >
                            <Show when={props.isFetchingNextPage} fallback={<span>Scroll to load more</span>}>
                              <span class="inline-flex items-center gap-2">
                                <CgSpinner class="animate-spin shrink-0" />
                                Loading more...
                              </span>
                            </Show>
                          </td>
                        )}
                      >
                        <For each={row()!.getVisibleCells()}>
                          {(cell) => {
                            const isRightAligned = RIGHT_ALIGNED_COLUMN_IDS.has(cell.column.id);

                            return (
                              <td
                                class={classnames(
                                  "min-w-0 flex min-h-[76px] items-center px-3 py-2.5 text-sm",
                                  isRightAligned && "justify-end",
                                )}
                                style={{ width: `${cell.column.getSize()}px` }}
                              >
                                {flexRender(cell.column.columnDef.cell, cell.getContext())}
                              </td>
                            );
                          }}
                        </For>
                      </Show>
                    </tr>
                  );
                }}
              </For>
            </tbody>
          </table>
        </div>
      </Show>
    </div>
  );
};
