import { Dialog } from "@kobalte/core/dialog";
import { FaSolidCog, FaSolidX } from "solid-icons/fa";

import { useSettings } from "./context/SettingsContext";

export const SettingsButton = () => {
  const { modes, setModes } = useSettings();

  return (
    <Dialog>
      <Dialog.Trigger class="btn-tertiary w-fit p-2 border text-sm">
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
                <input type="checkbox" checked={modes.mainnets} onChange={() => setModes({ ...modes, mainnets: !modes.mainnets })} />
                <label>Mainnet Mode</label>
              </div>
            </div>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <input type="checkbox" checked={modes.devnets} onChange={() => setModes({ ...modes, devnets: !modes.devnets })} />
                <label>Devnet Mode</label>
              </div>
            </div>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <input type="checkbox" checked={modes.testnets} onChange={() => setModes({ ...modes, testnets: !modes.testnets })} />
                <label>Testnet Mode</label>
              </div>
            </div>
          </Dialog.Content>
        </div>
      </Dialog.Portal>
    </Dialog>
  );
};
