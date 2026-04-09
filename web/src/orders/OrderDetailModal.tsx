import "../navbar/dialog.css";

import { Dialog } from "@kobalte/core/dialog";
import { useConnection } from "@wagmi/solid";
import { FaSolidX } from "solid-icons/fa";
import { type Component, Show } from "solid-js";

import { useBlockTimestamp } from "../hooks/useBlockTimestamp";
import { useMoneroHeight } from "../hooks/useMoneroHeight";
import type { Offer } from "../utils/offers";
import { OrderActions } from "./OrderActions";
import { OrderEvents } from "./OrderEvents";
import { OrderInfo } from "./OrderInfo";

export const OrderDetailModal: Component<{
  offer: Offer | null;
  onClose: () => void;
}> = (props) => {
  const connection = useConnection();
  const userAddress = () => connection().address;

  const blockTaken = () => props.offer?.blockTaken;
  const takenTimestamp = useBlockTimestamp(blockTaken);
  const moneroHeight = useMoneroHeight(() => takenTimestamp.data);

  return (
    <Dialog open={!!props.offer} onOpenChange={(open) => { if (!open) props.onClose(); }}>
      <Dialog.Portal>
        <Dialog.Overlay class="dialog__overlay" />
        <div class="dialog__positioner">
          <Dialog.Content class="card !rounded-2xl p-4 w-full max-w-lg max-h-[90vh] overflow-y-auto relative">
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
                  <div class="space-y-2">
                    <OrderInfo offer={offer()} restoreHeight={moneroHeight.data} userAddress={userAddress()} />
                    <OrderEvents offer_id={offer().id /* eslint-disable-line no-restricted-syntax */} lastupdate={offer().lastupdate} />
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
