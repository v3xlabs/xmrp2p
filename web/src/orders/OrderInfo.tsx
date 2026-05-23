import classnames from "classnames";
import { CgArrowRight } from "solid-icons/cg";
import { type Component, Show } from "solid-js";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import type { Offer } from "../hooks/useOffers";
import { getXmrRate, isXmrSide } from "../utils/escrow";
import { StatusBadge } from "./StatusBadge";

export const OrderInfo: Component<{
  offer: Offer;
  restoreHeight?: number;
  userAddress: string | undefined;
}> = (props) => {
  const xmrAmount = () => formatUnits(props.offer.xmrAmount, 12);

  const tokens = () => [
    <div class="bg-(--thorin-background-secondary) rounded-lg p-3">
      <div class="text-xs text-(--thorin-text-secondary) mb-1">ETH Amount</div>
      <div class="flex items-center gap-1 font-medium">
        <img src={ethIcon} alt="ETH" class="w-4 h-4" />
        {formatEther(props.offer.amount)}
      </div>
    </div>,
    <div class="absolute left-1/2 -translate-x-1/2 top-1/2 -translate-y-1/2">
      <CgArrowRight />
    </div>,
    <div class="bg-(--thorin-background-secondary) rounded-lg p-3">
      <div class="text-xs text-(--thorin-text-secondary) mb-1">XMR Amount</div>
      <div class="flex items-center gap-1 font-medium">
        <img src={xmrIcon} alt="XMR" class="w-4 h-4" />
        {xmrAmount()}
      </div>
    </div>,
  ];

  const reverse = () => (props.offer.state === 1 && props.offer.kind === 1) || (props.offer.state > 1 && isXmrSide(props.offer, props.userAddress));

  return (
    <div class="space-y-2">
      <div class="grid grid-cols-2 gap-2 relative">
        {reverse() ? tokens().reverse() : tokens()}
      </div>
      <div class="bg-(--thorin-background-secondary) rounded-lg p-3 space-y-1.5">
        <div class="flex justify-between text-sm">
          <span class="text-(--thorin-text-secondary)">Status</span>
          <span>
            <StatusBadge state={props.offer.state} />
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-(--thorin-text-secondary)">Order Type</span>
          <span
            class={classnames(
              "text-xs font-medium px-1.5 py-0.5 rounded",
              props.offer.kind === 1
                ? "bg-(--thorin-green-surface) text-(--thorin-green-primary)"
                : "bg-(--thorin-red-surface) text-(--thorin-red-primary)",
            )}
          >
            {props.offer.kind === 1 ? "Buy" : "Sell"}
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-(--thorin-text-secondary)">Rate</span>
          <span>
            {formatUnits(getXmrRate(props.offer), 12)}
            {" "}
            XMR/ETH
          </span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-(--thorin-text-secondary)">Deposit</span>
          <span>
            {formatEther(props.offer.deposit)}
            {" "}
            ETH
          </span>
        </div>
      </div>
      <Show when={
        props.offer.t0 > 0n
        || props.offer.t1 > 0n
        || props.restoreHeight
        || props.offer.blockTaken
      }
      >
        <div class="bg-(--thorin-background-secondary) rounded-lg p-3 space-y-1.5">
          <Show when={props.offer.t0 > 0n}>
            <div class="flex justify-between text-sm">
              <span class="text-(--thorin-text-secondary)">Ready deadline (t0)</span>
              <span>{new Date(Number(props.offer.t0) * 1000).toLocaleString()}</span>
            </div>
          </Show>
          <Show when={props.offer.t1 > 0n}>
            <div class="flex justify-between text-sm">
              <span class="text-(--thorin-text-secondary)">Claim deadline (t1)</span>
              <span>{new Date(Number(props.offer.t1) * 1000).toLocaleString()}</span>
            </div>
          </Show>
          <Show when={props.restoreHeight || props.offer.blockTaken}>
            <div class="flex justify-between text-sm">
              <span class="text-(--thorin-text-secondary)">Block taken</span>
              <span class="flex items-center gap-2">
                <span class="flex items-center gap-1">
                  <img src={xmrIcon} alt="XMR" class="w-3 h-3" />
                  <span class="">{props.restoreHeight?.toString()}</span>
                </span>
                <span class="h-full w-px bg-(--thorin-border)"></span>
                <span class="flex items-center gap-1">
                  <img src={ethIcon} alt="ETH" class="w-3 h-3" />
                  <span class="">{props.offer.blockTaken?.toString()}</span>
                </span>
              </span>
            </div>
          </Show>
        </div>
      </Show>
    </div>
  );
};
