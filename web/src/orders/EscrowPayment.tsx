import { type Component, createMemo, Show } from "solid-js";

import type { Offer } from "../hooks/useOffers";
import {
  createMoneroPaymentUri,
  getEscrowAddress,
  getXmrAmount,
} from "../utils/escrow";
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
      <div class="flex justify-between items-stretch h-fit gap-2">
        <div class="flex flex-col justify-between gap-1 pb-2">
          <div class="space-y-1">
            <h4 class="text-sm font-bold">Send XMR</h4>
            <p class="text-xs text-(--thorin-text-secondary) leading-relaxed pb-2">
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
            <p class="text-xs text-(--thorin-text-secondary) leading-relaxed">
              Once the evm-side has confirmed the deposit, the swap will proceed.
            </p>
          </div>
          <div class="">
            <button class="btn-primary w-fit py-2 text-sm" onClick={() => navigator.clipboard.writeText(escrowAddress()!)}>
              Copy Address
            </button>
          </div>
        </div>
        <Show when={paymentUri()}>
          {uri => (
            <div class="flex flex-col items-center gap-2">
              <QRCodeDisplay data={uri()} />
            </div>
          )}
        </Show>
      </div>
    </div>
  );
};
