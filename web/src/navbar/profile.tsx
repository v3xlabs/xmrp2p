import { createQuery } from "@tanstack/solid-query";
import { useConnection, useDisconnect } from "@wagmi/solid";
import { FaSolidGear } from "solid-icons/fa";
import { Show } from "solid-js";

import { Addr, truncateAddress } from "../utils/address";
import { queryKeys } from "../utils/queryKeys";
import { useEnsName } from "../utils/useEnstate";
import { ConnectModal } from "./connectmodal";

export const UserProfile = () => {
  const connection = useConnection();
  const disconnect = useDisconnect();
  const name = createQuery(() => ({ queryKey: queryKeys.address(connection().address ?? ""), queryFn: () => useEnsName(connection().address), enabled: !!connection().address }));

  return (
    <Show when={connection().isConnected} fallback={<ConnectModal />}>
      <div class="group relative h-full">
        <div class="bg-(--thorin-background-primary) h-full border rounded-md border-(--thorin-border) flex items-center gap-2 p-1">
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
                : "font-bold px-2"
            }
            >
              {truncateAddress(connection().address)}
            </div>
          </div>
        </div>
        <div class="hidden group-hover:block absolute right-0">
          <div class="card p-1 space-y-1 min-w-48">
            <div class="py-1 px-2">
              <Addr address={connection().address} />
            </div>
            <button class="w-full btn flex items-center gap-2 text-start px-2 py-1">
              <FaSolidGear class="w-4 h-4" />
              Settings
            </button>
            <button class="w-full btn flex items-center gap-2 text-start px-2 py-1" onClick={() => disconnect.mutate()}>
              Logout
            </button>
          </div>
        </div>
      </div>
    </Show>
  );
};
