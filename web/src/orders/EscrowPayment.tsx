import { type Component, createMemo, Show } from "solid-js";

import {
  createMoneroPaymentUri,
  getEscrowAddress,
  getXmrAmount,
} from "../utils/escrow";
import type { Offer } from "../utils/offers";
import { KeyDisplay } from "./KeyDisplay";
import { QRCodeDisplay } from "./QRCode";

export const EscrowPayment: Component<{
  offer: Offer;
}> = (props) => {
  const escrowAddress = createMemo(() => getEscrowAddress(props.offer));
  const xmrAmount = createMemo(() => getXmrAmount(props.offer));

  const paymentUri = createMemo(() => {
    const addr = escrowAddress();

    if (!addr) return null;

    return createMoneroPaymentUri(addr, xmrAmount());
  });

  return (
    <div class="space-y-3">
      <h4 class="text-sm font-bold">Send XMR to Escrow</h4>
      <p class="text-xs text-(--thorin-text-secondary)">
        Scan this QR code with your Monero wallet to send
        {" "}
        <span class="font-semibold">
          {xmrAmount()}
          {" "}
          XMR
        </span>
        {" "}
        to the escrow address.
      </p>
      <Show when={paymentUri()}>
        {uri => (
          <div class="flex flex-col items-center gap-2">
            <QRCodeDisplay data={uri()} />
          </div>
        )}
      </Show>
      <Show when={escrowAddress()}>
        {addr => <KeyDisplay label="Escrow Monero Address" value={addr()} />}
      </Show>
      <p class="text-xs text-(--thorin-text-secondary)">
        Once the evm-side has confirmed the deposit, the offer will proceed
      </p>
    </div>
  );
};
