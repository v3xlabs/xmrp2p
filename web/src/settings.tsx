import { Dialog } from "@kobalte/core/dialog";
import { FaSolidCog, FaSolidX } from "solid-icons/fa";

import { useSettings } from "./context/SettingsContext";

export const SettingsButton = () => {
  const { devnetMode, setDevnetMode, testnetMode, setTestnetMode } = useSettings();

  return (
    <Dialog>
      <Dialog.Trigger class="btn-tertiary w-fit py-2 text-sm">
        <FaSolidCog />
      </Dialog.Trigger>
      <Dialog.Portal>
        <Dialog.Overlay class="dialog__overlay" />
        <div class="dialog__positioner">
          <Dialog.Content class="card !rounded-2xl p-4 w-full max-w-lg max-h-[90vh] overflow-y-auto relative">
            <Dialog.Title class="p-2 center font-bold">
              Settings
            </Dialog.Title>
            <Dialog.CloseButton class="btn aspect-square p-2 absolute top-2 right-2">
              <FaSolidX />
            </Dialog.CloseButton>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <input type="checkbox" checked={devnetMode()} onChange={() => setDevnetMode(!devnetMode())} />
                <label>Devnet Mode</label>
              </div>
            </div>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <input type="checkbox" checked={testnetMode()} onChange={() => setTestnetMode(!testnetMode())} />
                <label>Testnet Mode</label>
              </div>
            </div>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog>
  );
};
