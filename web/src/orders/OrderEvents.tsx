import { CgSpinner } from "solid-icons/cg";
import { type Component, For, Show } from "solid-js";

import { useOfferEvents } from "../hooks/useOfferEvents";
import { StatusBadge } from "./StatusBadge";

export const OrderEvents: Component<{
  offer_id: bigint;
  lastupdate: bigint;
}> = (props) => {
  const events = useOfferEvents(
    () => props.offer_id,
    () => props.lastupdate,
  );

  return (
    <div class="bg-(--thorin-background-secondary) rounded-lg p-3">
      <div class="text-xs font-medium text-(--thorin-text-secondary) uppercase tracking-wider mb-2">
        Event History
      </div>
      <Show
        when={events.data}
        fallback={(
          <div class="flex justify-center py-2">
            <CgSpinner class="animate-spin text-(--thorin-text-secondary)" />
          </div>
        )}
      >
        {data => (
          <div class="space-y-1">
            <For each={data()}>
              {event => (
                <div class="flex items-center justify-between py-1 border-b border-(--thorin-border) last:border-0">
                  <StatusBadge state={event.state} />
                  <div class="flex items-center gap-3 text-xs text-(--thorin-text-secondary) tabular-nums">
                    <span>{new Date(Number(event.timestamp) * 1000).toLocaleString()}</span>
                    <span class="font-mono opacity-60">
                      {event.transactionHash.slice(0, 6)}
                      ...
                      {event.transactionHash.slice(-4)}
                    </span>
                  </div>
                </div>
              )}
            </For>
          </div>
        )}
      </Show>
    </div>
  );
};
