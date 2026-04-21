import { createMemo, For, Show, Suspense } from "solid-js";

import type { Offer } from "./hooks/useOffers";
import { useOffers } from "./hooks/useOffers";

export const Testing = () => {
  const x = useOffers();
  const allOffers = createMemo(() =>
    (x.data?.pages.flatMap(page => page.offers) ?? []) as Offer[],
  );

  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <Show when={x.isSuccess}>
          <For each={allOffers()}>
            {offer => (
              <div>
                {offer.owner}
              </div>
            )}
          </For>
        </Show>
        <Show when={x.isError}>
          {x.error?.message}
        </Show>
        <Show when={x.isPending}>
          Pending...
        </Show>
      </Suspense>
    </div>
  );
};
