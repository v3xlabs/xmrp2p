import "./dialog.css";

import { Dialog } from "@kobalte/core/dialog";
import { useConnect, useConnectors } from "@wagmi/solid";
import { FaSolidChevronRight, FaSolidSpinner, FaSolidX } from "solid-icons/fa";
import { For, Show } from "solid-js";

export const ConnectModal = () => {
    const connectors = useConnectors();
    const connect = useConnect();

    return (
        <Dialog>
            <Dialog.Trigger class="btn-primary">
                Connect
            </Dialog.Trigger>
            <Dialog.Portal>
                <Dialog.Overlay class="dialog__overlay" />
                <div class="dialog__positioner">
                    <Dialog.Content class="card p-2 w-full max-w-sm">
                        <div class="dialog__header">
                            <Dialog.Title class="p-2 center font-bold">
                                Choose a wallet
                            </Dialog.Title>
                            <Dialog.CloseButton class="btn aspect-square p-2">
                                <FaSolidX />
                            </Dialog.CloseButton>
                        </div>
                        <div class="">
                            <For each={connectors()}>
                                {
                                    connector => (
                                        <button
                                          class="btn flex justify-between items-center hover:bg-(--thorin-background-disabled) w-full p-2 cursor-pointer rounded-md"
                                          onClick={() => connect.mutate({ connector })}
                                        >
                                            <span class="flex items-center gap-2">
                                                <span>
                                                    <Show when={connector.icon}>
                                                        <img src={connector.icon} class="w-8 rounded-sm" />
                                                    </Show>
                                                </span>
                                                <span>
                                                    {connector.name}
                                                </span>
                                            </span>
                                            <span>
                                                <Show when={connect.isPending}>
                                                    <FaSolidSpinner class="animate-spin" />
                                                </Show>
                                                <Show when={!connect.isPending}>
                                                    <FaSolidChevronRight />
                                                </Show>
                                            </span>
                                        </button>
                                    )
                                }
                            </For>
                        </div>
                    </Dialog.Content>
                </div>
            </Dialog.Portal>
        </Dialog>
    );
};
