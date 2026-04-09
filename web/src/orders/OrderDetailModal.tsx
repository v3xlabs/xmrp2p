import "../navbar/dialog.css";

import { Dialog } from "@kobalte/core/dialog";
import { useConnection } from "@wagmi/solid";
import classnames from "classnames";
import { CgArrowRight, CgSpinner } from "solid-icons/cg";
import { FaSolidX } from "solid-icons/fa";
import { type Component, Show } from "solid-js";
import { match } from "ts-pattern";
import { formatEther, formatUnits } from "viem";

import ethIcon from "../assets/eth.svg";
import xmrIcon from "../assets/xmr.svg";
import { useApp } from "../hooks/useApp";
import { useBlockTimestamp } from "../hooks/useBlockTimestamp";
import { useCancelOrder } from "../hooks/useCancelOrder";
import { useClaimOrder } from "../hooks/useClaimOrder";
import { useMoneroHeight } from "../hooks/useMoneroHeight";
import { useQuitOrder } from "../hooks/useQuitOrder";
import { useReadyOrder } from "../hooks/useReadyOrder";
import { useTakeOrder } from "../hooks/useTakeOrder";
import { isEvmSide, isOwner, isXmrSide } from "../utils/escrow";
import { getStoredKeys } from "../utils/keyStore";
import type { Offer } from "../utils/offers";
import { EscrowSpendKeys, EscrowViewKeys } from "./EscrowKeys";
import { EscrowPayment } from "./EscrowPayment";
import { StatusBadge } from "./StatusBadge";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const now = () => Math.floor(Date.now() / 1000);

const OrderInfo: Component<{ offer: Offer; restoreHeight?: number; userAddress: string | undefined; }> = (props) => {
  const xmrAmount = () => {
    const val = props.offer.amount * props.offer.price / 10n ** 18n;

    return formatUnits(val, 12);
  };

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

  return (
    <div class="space-y-2">
      <div class="grid grid-cols-2 gap-2 relative">
        {
          isXmrSide(props.offer, props.userAddress) ? tokens().reverse() : tokens()
        }
      </div>
      <div class="bg-(--thorin-background-secondary) rounded-lg p-3 space-y-1.5">
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
          <span class="text-(--thorin-text-secondary)">Status</span>
          <span>
            <StatusBadge state={props.offer.state} />
          </span>
        </div>

        <div class="flex justify-between text-sm">
          <span class="text-(--thorin-text-secondary)">Rate</span>
          <span>
            {formatUnits(props.offer.price, 12)}
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
    </div>
  );
};

const OrderActions: Component<{
  offer: Offer;
  onClose: () => void;
  restoreHeight?: number;
}> = (props) => {
  const connection = useConnection();
  const { chainId } = useApp();
  const cancelOrder = useCancelOrder();
  const takeOrder = useTakeOrder();
  const readyOrder = useReadyOrder();
  const claimOrder = useClaimOrder();
  const quitOrder = useQuitOrder();

  const userAddress = () => connection().address;
  const storedKeys = () => {
    const addr = userAddress();

    if (!addr) return null;

    return getStoredKeys(chainId()!, props.offer.id, addr); // eslint-disable-line no-restricted-syntax
  };

  const userIsOwner = () => isOwner(props.offer, userAddress());
  const userIsEvmSide = () => isEvmSide(props.offer, userAddress());
  const userIsXmrSide = () => isXmrSide(props.offer, userAddress());

  const isAnyPending = () =>
    cancelOrder.isPending
    || takeOrder.isPending
    || readyOrder.isPending
    || claimOrder.isPending
    || quitOrder.isPending;

  const handleCancel = () => cancelOrder.mutate(props.offer.id); // eslint-disable-line no-restricted-syntax
  const handleTake = () => takeOrder.mutate(props.offer);
  const handleReady = () => readyOrder.mutate(props.offer.id); // eslint-disable-line no-restricted-syntax

  const handleClaim = () => {
    const keys = storedKeys();

    if (!keys) return;

    claimOrder.mutate({
      offer_id: props.offer.id, // eslint-disable-line no-restricted-syntax
      privateSpendKey: BigInt(keys.privateSpendKey),
    });
  };

  const handleQuit = () => {
    const keys = storedKeys();

    if (!keys) return;

    quitOrder.mutate({
      offer_id: props.offer.id, // eslint-disable-line no-restricted-syntax
      privateSpendKey: BigInt(keys.privateSpendKey),
      privateViewKey: BigInt(keys.privateViewKey),
    });
  };

  const isBeforeT0 = () => props.offer.t0 > 0n && now() <= Number(props.offer.t0);
  const isAfterT0 = () => props.offer.t0 > 0n && now() > Number(props.offer.t0);
  const isAfterT1 = () => props.offer.t1 > 0n && now() > Number(props.offer.t1);
  const isBeforeT1 = () => props.offer.t1 > 0n && now() <= Number(props.offer.t1);

  return (
    <div class="space-y-3">
      {match({ state: props.offer.state, userIsOwner: userIsOwner(), userIsEvmSide: userIsEvmSide(), userIsXmrSide: userIsXmrSide() })
        .with({ state: 1, userIsOwner: true }, () => (
          <button
            class={classnames("btn w-full py-2 text-sm border border-(--thorin-red-primary) text-(--thorin-red-primary)")}
            disabled={isAnyPending()}
            onClick={handleCancel}
          >
            <Show when={cancelOrder.isPending} fallback="Cancel Order">
              <CgSpinner class="animate-spin inline mr-1" />
              Cancelling...
            </Show>
          </button>
        ))
        .with({ state: 1, userIsOwner: false }, () => (
          <Show
            when={userAddress()}
            fallback={<div class="text-center text-sm text-(--thorin-text-secondary) py-2">Connect wallet to take this order</div>}
          >
            <Show when={props.offer.counterparty === ZERO_ADDRESS || props.offer.counterparty.toLowerCase() === userAddress()?.toLowerCase()}>
              <button
                class="btn-primary w-full py-2 btn-lg"
                disabled={isAnyPending()}
                onClick={handleTake}
              >
                <Show when={takeOrder.isPending} fallback="Take Order">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Taking...
                </Show>
              </button>
            </Show>
          </Show>
        ))
        .with({ state: 2, userIsEvmSide: true }, () => (
          <div class="space-y-2">
            <Show when={storedKeys()}>
              {keys => <EscrowViewKeys offer={props.offer} storedKeys={keys()} restoreHeight={props.restoreHeight} />}
            </Show>
            <Show when={isBeforeT0()}>
              <button
                class="btn-primary w-full py-2 btn-lg"
                disabled={isAnyPending()}
                onClick={handleReady}
              >
                <Show when={readyOrder.isPending} fallback="Confirm XMR Received (Ready)">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Confirming...
                </Show>
              </button>
            </Show>
            <Show when={storedKeys() && (isBeforeT0() || isAfterT1())}>
              <button
                class={classnames("btn w-full py-2 text-sm border border-(--thorin-orange-primary) text-(--thorin-orange-primary)")}
                disabled={isAnyPending()}
                onClick={handleQuit}
              >
                <Show when={quitOrder.isPending} fallback="Quit (Refund Both Parties)">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Quitting...
                </Show>
              </button>
            </Show>
            <Show when={!storedKeys()}>
              <div class="text-xs text-(--thorin-orange-primary) bg-(--thorin-orange-surface) rounded p-2">
                No keys found for this order. You may have created/taken it from a different browser.
              </div>
            </Show>
          </div>
        ))
        .with({ state: 2, userIsXmrSide: true }, () => (
          <div class="space-y-2">
            <EscrowPayment offer={props.offer} />
            <Show when={isAfterT0() && isBeforeT1() && storedKeys()}>
              <button
                class="btn-primary w-full py-2 btn-lg"
                disabled={isAnyPending()}
                onClick={handleClaim}
              >
                <Show when={claimOrder.isPending} fallback="Claim (Ready deadline passed)">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Claiming...
                </Show>
              </button>
            </Show>
          </div>
        ))
        .with({ state: 5, userIsXmrSide: true }, () => (
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-green-primary) text-center py-1 font-medium">
              XMR deposit verified by buyer
            </div>
            <Show when={isBeforeT1() && storedKeys()}>
              <button
                class="btn-primary w-full py-2 btn-lg"
                disabled={isAnyPending()}
                onClick={handleClaim}
              >
                <Show when={claimOrder.isPending} fallback="Claim ETH">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Claiming...
                </Show>
              </button>
            </Show>
            <Show when={!storedKeys()}>
              <div class="text-xs text-(--thorin-orange-primary) bg-(--thorin-orange-surface) rounded p-2">
                No keys found for this order. You may have created/taken it from a different browser.
              </div>
            </Show>
          </div>
        ))
        .with({ state: 5, userIsEvmSide: true }, () => (
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-text-secondary) text-center py-2">
              XMR verified. Waiting for the seller to claim...
            </div>
            <Show when={storedKeys()}>
              {keys => <EscrowViewKeys offer={props.offer} storedKeys={keys()} restoreHeight={props.restoreHeight} />}
            </Show>
            <Show when={isAfterT1() && storedKeys()}>
              <button
                class={classnames("btn w-full py-2 text-sm border border-(--thorin-orange-primary) text-(--thorin-orange-primary)")}
                disabled={isAnyPending()}
                onClick={handleQuit}
              >
                <Show when={quitOrder.isPending} fallback="Quit (Claim deadline expired)">
                  <CgSpinner class="animate-spin inline mr-1" />
                  Quitting...
                </Show>
              </button>
            </Show>
          </div>
        ))
        .with({ state: 6 }, () => (
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-green-primary) text-center py-1 font-medium">
              Trade completed successfully
            </div>
            <Show when={storedKeys() && userIsEvmSide()}>
              <EscrowSpendKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
          </div>
        ))
        .with({ state: 4 }, () => (
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-orange-primary) text-center py-1 font-medium">
              Order refunded
            </div>
            <Show when={storedKeys() && userIsXmrSide()}>
              <EscrowSpendKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
          </div>
        ))
        .with({ state: 3 }, () => (
          <div class="text-sm text-(--thorin-text-secondary) text-center py-2">
            Order was cancelled
          </div>
        ))
        .otherwise(() => null)}

      <Show when={cancelOrder.isError || takeOrder.isError || readyOrder.isError || claimOrder.isError || quitOrder.isError}>
        <div class="text-xs text-(--thorin-red-primary) bg-(--thorin-red-surface) rounded p-2 break-all">
          {(cancelOrder.error ?? takeOrder.error ?? readyOrder.error ?? claimOrder.error ?? quitOrder.error)?.message ?? "Transaction failed"}
        </div>
      </Show>

      <Show when={cancelOrder.isSuccess || takeOrder.isSuccess || readyOrder.isSuccess || claimOrder.isSuccess || quitOrder.isSuccess}>
        <div class="text-xs text-(--thorin-green-primary) bg-(--thorin-green-surface) rounded p-2">
          Transaction submitted successfully
        </div>
      </Show>
    </div>
  );
};

export const OrderDetailModal: Component<{
  offer: Offer | null;
  onClose: () => void;
}> = (props) => {
  const connection = useConnection();
  const userAddress = () => connection().address;

  const blockTaken = () => props.offer?.blockTaken;
  const takenTimestamp = useBlockTimestamp(blockTaken);
  const moneroHeight = useMoneroHeight(() => takenTimestamp.data);

  const roleLabel = () => {
    const offer = props.offer;

    if (!offer || !userAddress()) return null;

    if (isEvmSide(offer, userAddress())) return "You are the ETH side";

    if (isXmrSide(offer, userAddress())) return "You are the XMR side";

    if (isOwner(offer, userAddress())) return "You are the maker";

    return null;
  };

  return (
    <Dialog open={!!props.offer} onOpenChange={(open) => { if (!open) props.onClose(); }}>
      <Dialog.Portal>
        <Dialog.Overlay class="dialog__overlay" />
        <div class="dialog__positioner">
          <Dialog.Content class="card p-4 w-full max-w-lg max-h-[90vh] overflow-y-auto relative">
            <Show when={props.offer}>
              {offer => (
                <>
                  <div class="dialog__header">
                    <div class="flex items-center gap-2">
                      <Dialog.Title class="font-bold">
                        Order #
                        {offer().id.toString() /* eslint-disable-line no-restricted-syntax */}
                      </Dialog.Title>
                    </div>
                    <Dialog.CloseButton class="btn aspect-square p-2 absolute top-2 right-2">
                      <FaSolidX />
                    </Dialog.CloseButton>
                  </div>

                  <Show when={roleLabel()}>
                    {label => (
                      <div class="text-xs text-(--thorin-blue-primary) bg-(--thorin-blue-surface) rounded px-2 py-1 mb-3 inline-block">
                        {label()}
                      </div>
                    )}
                  </Show>

                  <div class="space-y-4">
                    <OrderInfo offer={offer()} restoreHeight={moneroHeight.data} userAddress={userAddress()} />
                    <OrderActions offer={offer()} onClose={props.onClose} restoreHeight={moneroHeight.data} />
                  </div>
                </>
              )}
            </Show>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog>
  );
};
