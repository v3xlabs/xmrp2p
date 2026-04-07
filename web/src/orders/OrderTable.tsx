import {
  createColumnHelper,
  createSolidTable,
  flexRender,
  getCoreRowModel,
} from "@tanstack/solid-table";
import classnames from "classnames";
import { type Component, createMemo, For, Show } from "solid-js";
import { match } from "ts-pattern";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import { type Offer, useOffers } from "../utils/offers";
import { StatusBadge } from "./StatusBadge";
import { truncateAddress } from "../utils/address";

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
          {isBuy ? "Buy XMR" : "Sell XMR"}
        </span>
      );
    },
  }),
  columnHelper.accessor("owner", {
    header: "Owner",
    cell: ({ row }) => (
      <div class="text-right tabular-nums font-medium">
        {truncateAddress(row.original.owner)}
      </div>
    ),
  }),
  columnHelper.accessor("counterparty", {
    header: "Counterparty",
    cell: ({ row }) => (
      <div class="text-right tabular-nums font-medium">
        {truncateAddress(row.original.counterparty)}
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
      <div class="text-right tabular-nums font-medium">
        {formatEther(row.original.amount)}
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
    id: "xmr_amount", // eslint-disable-line no-restricted-syntax
    header: () => (
      <div class="flex items-center gap-1 justify-end">
        <img src={xmrIcon} alt="XMR" class="w-4 h-4" />
        <span>XMR</span>
      </div>
    ),
    cell: ({ row }) => {
      const xmrAmount = formatEther(
        row.original.amount * row.original.price / 10n ** 12n,
      );

      return (
        <div class="text-right tabular-nums font-medium">{xmrAmount}</div>
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

export const OrderTable: Component = () => {
  const query = useOffers();

  const activeOffers = createMemo(() =>
    ((query?.data?.pages.flatMap(page => page) ?? []) as Offer[]).filter(offer => offer.state !== 0),
  );

  const table = createSolidTable(() => ({
    columns,
    data: activeOffers(),
    getCoreRowModel: getCoreRowModel(),
  }));

  return (
    <Show
      when={activeOffers().length > 0}
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
            .otherwise(() => "No open offers")}
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
              <tr class="hover:bg-(--thorin-background-secondary) transition-colors">
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
};
