/* eslint-disable no-restricted-syntax */
import { createColumnHelper, createSolidTable, flexRender, getCoreRowModel } from "@tanstack/solid-table";
import { type Component, For } from "solid-js";

type OrderId = string;
type Order = {
  id: OrderId;
  amount: number;
  price: number;
  state: "open" | "filled" | "cancelled";
  createdAt: Date;
  updatedAt: Date;
};

const columnHelper = createColumnHelper<Order>();

export const OrderTable: Component<{ orders: OrderId[]; }> = ({ orders }) => {
  const data = orders.map(order => ({
    id: order,
    amount: 0,
    price: 0,
    state: "open",
    createdAt: new Date(),
    updatedAt: new Date(),
  } as Order));
  const columns = [
    columnHelper.accessor("id", {
      header: "ID",
      cell: ({ row }) => row.original.id,
    }),
    columnHelper.accessor("amount", {
      header: "Amount",
      cell: ({ row }) => row.original.amount,
    }),
    columnHelper.accessor("price", {
      header: "Price",
      cell: ({ row }) => row.original.price,
    }),
    columnHelper.accessor("state", {
      header: "State",
      cell: ({ row }) => row.original.state,
    }),
  ];
  const table = createSolidTable({
    columns,
    data,
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
