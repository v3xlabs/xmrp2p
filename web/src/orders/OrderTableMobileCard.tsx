/* eslint-disable no-restricted-syntax */
import classnames from "classnames";
import { type Component, createMemo } from "solid-js";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import { type Offer } from "../hooks/useOffers";
import { Price } from "../swap/price";
import { Addr } from "../utils/address";
import { StatusBadge } from "./StatusBadge";

type OrderTableMobileCardProps = {
  offer: Offer;
  onSelectOffer: (offerId: bigint) => void;
};

export const OrderTableMobileCard: Component<OrderTableMobileCardProps> = (props) => {
  const xmrAmountValue = createMemo(() => props.offer.amount * props.offer.price / 10n ** 18n);

  return (
    <button
      type="button"
      class="card w-full cursor-pointer space-y-4 p-4 text-left transition-colors hover:bg-(--thorin-background-secondary)"
      onClick={() => props.onSelectOffer(props.offer.id)}
    >
      <div class="flex items-start justify-between gap-3">
        <div class="space-y-1">
          <div
            class={classnames(
              "text-sm font-medium",
              props.offer.kind === 1 ? "text-(--thorin-green-primary)" : "text-(--thorin-red-primary)",
            )}
          >
            {props.offer.kind === 1 ? "Buy" : "Sell"}
          </div>
        </div>
        <StatusBadge state={props.offer.state} />
      </div>

      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div>
          <div class="text-xs uppercase tracking-wider text-(--thorin-text-secondary)">Owner</div>
          <div class="mt-1 text-sm tabular-nums"><Addr address={props.offer.owner} /></div>
        </div>
        <div>
          <div class="text-xs uppercase tracking-wider text-(--thorin-text-secondary)">Counterparty</div>
          <div class="mt-1 text-sm tabular-nums"><Addr address={props.offer.counterparty} /></div>
        </div>
        <div>
          <div class="text-xs uppercase tracking-wider text-(--thorin-text-secondary)">Rate</div>
          <div class="mt-1 text-sm tabular-nums text-(--thorin-text-primary)">
            {formatUnits(props.offer.price, 12)}
            <span class="ml-1 text-xs text-(--thorin-text-secondary)">XMR/ETH</span>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-3 border-t border-(--thorin-border) pt-3">
        <div>
          <div class="flex items-center gap-1 text-xs uppercase tracking-wider text-(--thorin-text-secondary)">
            <img src={ethIcon} alt="ETH" class="h-4 w-4" />
            <span>ETH</span>
          </div>
          <div class="mt-1 text-sm font-medium tabular-nums">{formatEther(props.offer.amount)}</div>
          <div class="text-sm text-(--thorin-text-secondary)">
            <Price token={() => "eth"} amount={() => props.offer.amount} />
          </div>
        </div>
        <div>
          <div class="flex items-center gap-1 text-xs uppercase tracking-wider text-(--thorin-text-secondary)">
            <img src={xmrIcon} alt="XMR" class="h-4 w-4" />
            <span>XMR</span>
          </div>
          <div class="mt-1 text-sm font-medium tabular-nums">{formatUnits(xmrAmountValue(), 12)}</div>
          <div class="text-sm text-(--thorin-text-secondary)">
            <Price token={() => "xmr"} amount={() => xmrAmountValue()} />
          </div>
        </div>
      </div>
    </button>
  );
};
