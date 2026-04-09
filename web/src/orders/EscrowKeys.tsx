import { type Component, createMemo, createSignal, Show } from "solid-js";

import type { Offer } from "../hooks/useOffers";
import {
  combinePrivateKeys,
  createMoneroViewUri,
  createMoneroWalletUri,
  getEscrowAddress,
  toMoneroKeyHex,
} from "../utils/escrow";
import type { StoredOrderKeys } from "../utils/keyStore";
import { KeyDisplay } from "./KeyDisplay";
import { QRCodeDisplay } from "./QRCode";

export const EscrowViewKeys: Component<{
  offer: Offer;
  storedKeys: StoredOrderKeys;
  restoreHeight?: number;
}> = (props) => {
  const escrowAddress = createMemo(() => getEscrowAddress(props.offer));

  const combinedViewKey = createMemo(() => {
    const evmPrivateViewKey = BigInt(props.storedKeys.privateViewKey);
    const xmrPrivateViewKey = props.offer.xmrPrivateViewKey;

    if (!xmrPrivateViewKey) return null;

    return combinePrivateKeys(evmPrivateViewKey, xmrPrivateViewKey);
  });

  const viewUri = createMemo(() => {
    const addr = escrowAddress();
    const key = combinedViewKey();

    console.log("addr", addr);
    console.log("key", key);

    if (!addr || !key) return null;

    return createMoneroViewUri(addr, key, `XMRP2P-${props.offer.id}-view`, props.restoreHeight); // eslint-disable-line no-restricted-syntax
  });

  const [showKeys, setShowKeys] = createSignal(false);

  return (
    <>
      <div class="flex justify-between items-stretch h-fit gap-2">
        <div class="flex flex-col justify-between gap-1 pb-2">
          <div class="space-y-3">
            <h4 class="text-sm font-bold">Verify XMR Deposit</h4>
            <p class="text-xs text-(--thorin-text-secondary)">
              Scan this QR code to add the escrow as a view-only wallet. You can then verify the XMR was deposited.
            </p>
          </div>
          <div>
            <button class="btn-tertiary px-2 w-fit py-2 text-sm" onClick={() => setShowKeys(!showKeys())}>
              Show Keys
            </button>
          </div>
        </div>
        <div>
          <Show when={viewUri()}>
            {uri => (
              <div class="flex flex-col items-center gap-2">
                <QRCodeDisplay data={uri()} />
              </div>
            )}
          </Show>
        </div>
      </div>
      <div>
        <Show when={showKeys()}>
          <div>
            <Show when={escrowAddress()}>
              {addr => <KeyDisplay label="Escrow Monero Address" value={addr()} />}
            </Show>
            <Show when={combinedViewKey()}>
              {key => <KeyDisplay label="View Key" value={toMoneroKeyHex(key())} />}
            </Show>
          </div>
        </Show>
      </div>
    </>
  );
};

export const EscrowSpendKeys: Component<{
  offer: Offer;
  storedKeys: StoredOrderKeys;
  restoreHeight?: number;
}> = (props) => {
  const escrowAddress = createMemo(() => getEscrowAddress(props.offer));

  const combinedViewKey = createMemo(() => {
    const evmPrivateViewKey = props.storedKeys.role === "evm"
      ? BigInt(props.storedKeys.privateViewKey)
      : props.offer.evmPrivateViewKey;
    const xmrPrivateViewKey = props.storedKeys.role === "xmr"
      ? BigInt(props.storedKeys.privateViewKey)
      : props.offer.xmrPrivateViewKey;

    if (!evmPrivateViewKey || !xmrPrivateViewKey) return null;

    return combinePrivateKeys(evmPrivateViewKey, xmrPrivateViewKey);
  });

  const combinedSpendKey = createMemo(() => {
    const evmPrivateSpendKey = props.storedKeys.role === "evm"
      ? BigInt(props.storedKeys.privateSpendKey)
      : props.offer.evmPrivateSpendKey;
    const xmrPrivateSpendKey = props.storedKeys.role === "xmr"
      ? BigInt(props.storedKeys.privateSpendKey)
      : props.offer.xmrPrivateSpendKey;

    if (!evmPrivateSpendKey || !xmrPrivateSpendKey) return null;

    return combinePrivateKeys(evmPrivateSpendKey, xmrPrivateSpendKey);
  });

  const walletUri = createMemo(() => {
    const addr = escrowAddress();
    const spendKey = combinedSpendKey();
    const viewKey = combinedViewKey();

    if (!addr || !spendKey || !viewKey) return null;

    return createMoneroWalletUri(addr, spendKey, viewKey, `XMRP2P-${props.offer.id}-spend`, props.restoreHeight); // eslint-disable-line no-restricted-syntax
  });

  const [showKeys, setShowKeys] = createSignal(false);

  return (
    <div class="space-y-3">
      <div class="flex justify-between items-stretch h-fit gap-2">
        <div class="flex flex-col justify-between gap-1 pb-2">
          <div class="space-y-1">
            <h4 class="text-sm font-bold">Collect XMR</h4>
            <p class="text-xs text-(--thorin-text-secondary)">
              Scan this QR code to import the escrow wallet and sweep the XMR to your own wallet.
            </p>
          </div>
          <div>
            <button class="btn-primary w-fit py-2 text-sm" onClick={() => setShowKeys(!showKeys())}>
              Show Keys
            </button>
          </div>
        </div>
        <Show when={walletUri()}>
          {uri => (
            <div class="flex flex-col items-center gap-2 blur-md hover:blur-none">
              <QRCodeDisplay data={uri()} />
            </div>
          )}
        </Show>
      </div>
      <Show when={showKeys()}>
        <Show when={escrowAddress()}>
          {addr => <KeyDisplay label="Escrow Monero Address" value={addr()} />}
        </Show>
        <Show when={combinedSpendKey()}>
          {key => <KeyDisplay label="Spend Key" value={toMoneroKeyHex(key())} />}
        </Show>
        <Show when={combinedViewKey()}>
          {key => <KeyDisplay label="View Key" value={toMoneroKeyHex(key())} />}
        </Show>
      </Show>
    </div>
  );
};
