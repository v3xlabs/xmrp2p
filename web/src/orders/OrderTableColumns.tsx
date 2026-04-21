/* eslint-disable no-restricted-syntax */
import { createColumnHelper } from "@tanstack/solid-table";
import classnames from "classnames";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import { getOfferXmrAmount } from "../hooks/offerCodec";
import { type Offer } from "../hooks/useOffers";
import { Price } from "../swap/price";
import { Addr } from "../utils/address";
import { StatusBadge } from "./StatusBadge";

const columnHelper = createColumnHelper<Offer>();

export const orderTableColumns = [
  columnHelper.accessor("kind", {
    size: 88,
    minSize: 72,
    header: "Side",
    cell: ({ row }) => (
      <span
        class={classnames(
          "font-medium text-sm",
          row.original.kind === 1 ? "text-(--thorin-green-primary)" : "text-(--thorin-red-primary)",
        )}
      >
        {row.original.kind === 1 ? "Buy" : "Sell"}
      </span>
    ),
  }),
  columnHelper.accessor("owner", {
    size: 160,
    minSize: 150,
    header: "Owner",
    cell: ({ row }) => (
      <div class="text-left tabular-nums">
        <Addr address={row.original.owner} />
      </div>
    ),
  }),
  columnHelper.accessor("counterparty", {
    size: 190,
    minSize: 170,
    header: "Counterparty",
    cell: ({ row }) => (
      <div class="text-left tabular-nums">
        <Addr address={row.original.counterparty} />
      </div>
    ),
  }),
  columnHelper.accessor("price", {
    size: 144,
    minSize: 132,
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
    size: 148,
    minSize: 132,
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
    size: 184,
    minSize: 168,
    header: () => (
      <div class="flex items-center gap-1 justify-end">
        <img src={xmrIcon} alt="XMR" class="w-4 h-4" />
        <span>XMR</span>
      </div>
    ),
    cell: ({ row }) => {
      const xmrAmountValue = getOfferXmrAmount(row.original);

      return (
        <div class="text-right tabular-nums">
          <div class="font-medium">{formatUnits(xmrAmountValue, 12)}</div>
          <div>
            <Price token={() => "xmr"} amount={() => xmrAmountValue} />
          </div>
        </div>
      );
    },
  }),
  columnHelper.accessor("state", {
    size: 124,
    minSize: 112,
    header: () => <div class="text-right">Status</div>,
    cell: ({ row }) => (
      <div class="flex w-full items-center justify-end">
        <StatusBadge state={row.original.state} />
      </div>
    ),
  }),
];
