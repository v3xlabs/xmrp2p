import { Tabs } from "@kobalte/core/tabs";
import {
  createColumnHelper,
  createSolidTable,
  flexRender,
  getCoreRowModel,
} from "@tanstack/solid-table";
import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import { type Component, createMemo, createSignal, For, Show } from "solid-js";
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
        <div>
          {formatUnits(row.original.price, 12)}
        </div>
        <span class="ml-1 text-xs opacity-60">XMR/ETH</span>
      </div>
    ),
  }),
  columnHelper.display({
    id: "eth_amount", // eslint-disable-line no-restricted-syntax
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
    id: "xmr_amount", // eslint-disable-line no-restricted-syntax
    header: () => (
      <div class="flex items-center gap-1 justify-end">
        <img src={xmrIcon} alt="XMR" class="w-4 h-4" />
        <span>XMR</span>
      </div>
    ),
    cell: ({ row }) => {
      const xmrAmountValue = row.original.amount * row.original.price / 10n ** 18n;
      const xmrAmount = formatUnits(
        xmrAmountValue,
        12,
      );

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

export const OrderTable: Component = () => {
  const [selectedOfferId, setSelectedOfferId] = createSignal<bigint | null>(null);
  const query = useOffers(selectedOfferId);

  const allOffers = createMemo(() =>
    ((query?.data?.pages.flat() ?? []) as Offer[]).filter(offer => offer.state !== 0),
  );

  const selectedOffer = createMemo(() => {
    const offerId = selectedOfferId();

    if (!offerId) return null;

    return allOffers().find(o => o.id === offerId) ?? null; // eslint-disable-line no-restricted-syntax
  });

  const openOffers = createMemo(() =>
    allOffers().filter(offer => !isPast(offer)),
  );

  const pastOffers = createMemo(() =>
    allOffers().filter(isPast),
  );

  const openTable = createSolidTable({
    columns,
    data: openOffers(),
    getCoreRowModel: getCoreRowModel(),
  });

  const pastTable = createSolidTable({
    columns,
    data: pastOffers(),
    getCoreRowModel: getCoreRowModel(),
  });

  const renderTable = (table: typeof openTable | typeof pastTable, offers: () => Offer[]) => (
    <Show
      when={offers().length > 0}
      fallback={(
        <div class="py-8 text-center text-(--thorin-text-secondary) text-sm">
          {match(query)
            .when(
              q => q.isPending,
              () => "Loading offers...",
            )
            .when(
              q => q.isError,
              () => "Failed to load offers",
            )
            .otherwise(() => "No orders")}
        </div>
      )}
    >
      <table class="w-full border-collapse">
        <thead>
          <For each={table.getHeaderGroups()}>
            {headerGroup => (
              <tr>
                <For each={headerGroup.headers}>
                  {header => (
                    <th class="border-b border-(--thorin-border) px-3 py-2 text-left text-xs font-medium text-(--thorin-text-secondary) uppercase tracking-wider">
                      {header.isPlaceholder
                        ? null
                        : flexRender(
                            header.column.columnDef.header,
                            header.getContext(),
                          )}
                    </th>
                  )}
                </For>
              </tr>
            )}
          </For>
        </thead>
        <tbody>
          <For each={table.getRowModel().rows}>
            {row => (
              <tr
                class="hover:bg-(--thorin-background-secondary) transition-colors cursor-pointer"
                onClick={() => setSelectedOfferId(row.original.id)} // eslint-disable-line no-restricted-syntax
              >
                <For each={row.getVisibleCells()}>
                  {cell => (
                    <td class="px-3 py-2.5 text-sm">
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext(),
                      )}
                    </td>
                  )}
                </For>
              </tr>
            )}
          </For>
        </tbody>
      </table>
      <Show when={query.hasNextPage}>
        <button class="btn" onClick={() => query.fetchNextPage()}>Load more</button>
      </Show>
    </Show>
  );

  return (
    <>
      <Tabs aria-label="Orders" defaultValue="open" class="relative">
        <div class="px-2 flex justify-between items-end">
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
          <div class="py-2">
            <Show when={query.isLoading || query.isFetching}>
              <CgSpinner class="animate-spin" />
            </Show>
          </div>
        </div>
        <div class="card p-2">
          <Tabs.Content value="open">
            {renderTable(openTable, openOffers)}
          </Tabs.Content>
          <Tabs.Content value="history">
            {renderTable(pastTable, pastOffers)}
          </Tabs.Content>
        </div>
      </Tabs>

      <OrderDetailModal
        offer={selectedOffer()}
        onClose={() => setSelectedOfferId(null)}
      />
    </>
  );
};
