
import { createColumnHelper, createSolidTable, flexRender, getCoreRowModel } from "@tanstack/solid-table";
import { type Component, For } from "solid-js";

import { type Offer, useBuyOffers } from "../utils/offers";

const columnHelper = createColumnHelper<Offer>();

export const OrderTable: Component = () => {
  const x = useBuyOffers();
  const columns = [
    columnHelper.accessor("id", {
      header: "ID",
    }),
    columnHelper.accessor("price", {
      header: "Price",
    }),
    columnHelper.accessor("state", {
      header: "State",
    }),
  ];
  const table = createSolidTable({
    columns,
    // TODO: fix this
    data: (x?.data ?? []) as Offer[],
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <table class="w-full border-collapse">
      <thead>
        <For each={table.getHeaderGroups()}>
          {headerGroup => (
            <tr>
              <For each={headerGroup.headers}>
                {header => (
                  <th class="border-b border-(--thorin-border) p-2 text-left">
                    {header.isPlaceholder
                      ? null
                      : flexRender(header.column.columnDef.header, header.getContext())}
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
            <tr>
              <For each={row.getVisibleCells()}>
                {cell => (
                  <td class="p-2">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                )}
              </For>
            </tr>
          )}
        </For>
      </tbody>
    </table>
  );
};
