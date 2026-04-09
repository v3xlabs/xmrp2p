import { useBlockNumber, useConnection } from "@wagmi/solid";
import { type Component, Match, Show, Switch } from "solid-js";

import { useApp } from "../hooks/useApp";
import type { Offer } from "../hooks/useOffers";
import { isEvmSide, isOwner, isXmrSide } from "../utils/escrow";
import { getStoredKeys } from "../utils/keyStore";
import { CancelAction } from "./actions/CancelAction";
import { ClaimAction } from "./actions/ClaimAction";
import { QuitAction } from "./actions/QuitAction";
import { ReadyAction } from "./actions/ReadyAction";
import { TakeAction } from "./actions/TakeAction";
import { EscrowSpendKeys, EscrowViewKeys } from "./EscrowKeys";
import { EscrowPayment } from "./EscrowPayment";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

export const OrderActions: Component<{
  offer: Offer;
  onClose: () => void;
  restoreHeight?: number;
}> = (props) => {
  const connection = useConnection();
  const { chainId } = useApp();
  const blockHeight = useBlockNumber();

  const userAddress = () => connection().address;
  const storedKeys = () => {
    const addr = userAddress();

    if (!addr) return null;

    return getStoredKeys(chainId()!, props.offer.id, addr); // eslint-disable-line no-restricted-syntax
  };

  const userIsOwner = () => isOwner(props.offer, userAddress());
  const userIsEvmSide = () => isEvmSide(props.offer, userAddress());
  const userIsXmrSide = () => isXmrSide(props.offer, userAddress());

  const now = () => blockHeight.data ?? 0;

  const isBeforeT0 = () => props.offer.t0 > 0n && now() <= Number(props.offer.t0);
  const isAfterT0 = () => props.offer.t0 > 0n && now() > Number(props.offer.t0);
  const isAfterT1 = () => props.offer.t1 > 0n && now() > Number(props.offer.t1);
  const isBeforeT1 = () => props.offer.t1 > 0n && now() <= Number(props.offer.t1);

  return (
    <div class="space-y-3">
      <Switch>
        <Match when={props.offer.state === 1 && userIsOwner()}>
          <CancelAction offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */} />
        </Match>
        <Match when={props.offer.state === 1 && !userIsOwner()}>
          <Show
            when={userAddress()}
            fallback={<div class="text-center text-sm text-(--thorin-text-secondary) py-2">Connect wallet to take this order</div>}
          >
            <Show when={props.offer.counterparty === ZERO_ADDRESS || props.offer.counterparty.toLowerCase() === userAddress()?.toLowerCase()}>
              <TakeAction offer={props.offer} />
            </Show>
          </Show>
        </Match>
        <Match when={props.offer.state === 2 && userIsEvmSide()}>
          <div class="space-y-2">
            <Show when={storedKeys()}>
              <EscrowViewKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
            <Show when={isBeforeT0()}>
              <ReadyAction offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */} />
            </Show>
            <Show when={storedKeys() && (isBeforeT0() || isAfterT1())}>
              <QuitAction
                offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */}
                storedKeys={storedKeys()!}
                label="Cancel Order"
              />
            </Show>
            <Show when={!storedKeys()}>
              <div class="text-xs text-(--thorin-orange-primary) bg-(--thorin-orange-surface) rounded p-2">
                No keys found for this order. You may have created/taken it from a different browser.
              </div>
            </Show>
          </div>
        </Match>
        <Match when={props.offer.state === 2 && userIsXmrSide()}>
          <div class="space-y-2">
            <EscrowPayment offer={props.offer} />
            <Show when={isAfterT0() && isBeforeT1() && storedKeys()}>
              <ClaimAction
                offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */}
                storedKeys={storedKeys()!}
                label="Claim (Ready deadline passed)"
              />
            </Show>
          </div>
        </Match>
        <Match when={props.offer.state === 5 && userIsXmrSide()}>
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-green-primary) text-center py-1 font-medium">
              XMR deposit verified by buyer
            </div>
            <Show when={isBeforeT1() && storedKeys()}>
              <ClaimAction
                offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */}
                storedKeys={storedKeys()!}
                label="Claim ETH"
              />
            </Show>
            <Show when={!storedKeys()}>
              <div class="text-xs text-(--thorin-orange-primary) bg-(--thorin-orange-surface) rounded p-2">
                No keys found for this order. You may have created/taken it from a different browser.
              </div>
            </Show>
          </div>
        </Match>
        <Match when={props.offer.state === 5 && userIsEvmSide()}>
          <div class="space-y-2">
            <Show when={storedKeys()}>
              <EscrowViewKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
            <div class="text-sm text-(--thorin-text-secondary) text-center py-2">
              XMR verified. Waiting for the seller to claim...
            </div>
            <Show when={isAfterT1() && storedKeys()}>
              <QuitAction
                offer_id={props.offer.id /* eslint-disable-line no-restricted-syntax */}
                storedKeys={storedKeys()!}
                label="Quit (Claim deadline expired)"
              />
            </Show>
          </div>
        </Match>
        <Match when={props.offer.state === 6}>
          <div class="space-y-2">
            <Show when={storedKeys() && userIsEvmSide()}>
              <EscrowSpendKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
            <div class="text-sm text-(--thorin-green-primary) text-center py-1 font-medium">
              Trade completed successfully
            </div>
          </div>
        </Match>
        <Match when={props.offer.state === 4}>
          <div class="space-y-2">
            <div class="text-sm text-(--thorin-orange-primary) text-center py-1 font-medium">
              Order refunded
            </div>
            <Show when={storedKeys() && userIsXmrSide()}>
              <EscrowSpendKeys offer={props.offer} storedKeys={storedKeys()!} restoreHeight={props.restoreHeight} />
            </Show>
          </div>
        </Match>
        <Match when={props.offer.state === 3}>
          <div class="text-sm text-(--thorin-text-secondary) text-center py-2">
            Order was cancelled
          </div>
        </Match>
      </Switch>
    </div>
  );
};
