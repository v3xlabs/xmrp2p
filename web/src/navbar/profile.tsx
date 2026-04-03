import { useConnection, useDisconnect } from "@wagmi/solid";
import { Show } from "solid-js";

import { truncateAddress } from "../utils/address";
import { ConnectModal } from "./connectmodal";

export const UserProfile = () => {
    const connection = useConnection();
    const disconnect = useDisconnect();

    return (
        <Show when={connection().isConnected} fallback={<ConnectModal />}>
            <div class="group relative">
                <div class="group-hover:bg-(--thorin-background-primary)">
                    {
                        connection().address && truncateAddress(connection().address)
                    }
                </div>
                <div class="hidden group-hover:block absolute right-0">
                    <div class="card p-1 space-y-1">
                        <div class="py-1 px-2">
                            {connection().address}
                        </div>
                        <button class="w-full btn text-start px-2 py-1" onClick={() => disconnect.mutate()}>
                            Logout
                        </button>
                    </div>
                </div>
            </div>
        </Show>
    );
};
