import { createMemo, For, Show, Suspense } from "solid-js";

import type { Offer } from "./utils/offers";
import { useOffers } from "./utils/offers";

export const Testing = () => {
  const x = useOffers();
  const allOffers = createMemo(() =>
    (x.data?.pages.flat() ?? []) as Offer[],
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
