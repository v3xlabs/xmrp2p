import { createQuery } from "@tanstack/solid-query";
import { useConnection, useDisconnect } from "@wagmi/solid";
import { Show } from "solid-js";

import { truncateAddress } from "../utils/address";
import { useEnsName } from "../utils/useEnstate";
import { ConnectModal } from "./connectmodal";

export const UserProfile = () => {
    const connection = useConnection();
    const disconnect = useDisconnect();
    const name = createQuery(() => ({ queryKey: ["addy", connection().address], queryFn: x => useEnsName(x.queryKey[1]) }));

    return (
        <Show when={connection().isConnected} fallback={<ConnectModal />}>
            <div class="group relative">
                <div class="group-hover:bg-(--thorin-background-primary) border border-transparent group-hover:border-(--thorin-border) flex items-center gap-2 p-1">
                    <Show when={name.isSuccess && name?.data?.avatar}>
                        <img src={name?.data?.avatar} class="w-7 rounded-md" />
                    </Show>
                    <div class="block leading-none text-sm">
                        <Show when={name.isSuccess && name?.data?.name}>
                            <div class="font-bold">
                                {name.data!.name}
                            </div>
                        </Show>
                        <div class={
                            name?.data?.name
                                ? "text-(--thorin-text-secondary)"
                                : "font-bold"
                        }
                        >
                            {truncateAddress(connection().address)}
                        </div>
                    </div>
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
