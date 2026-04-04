import { createMemo, For, Show, Suspense } from "solid-js";

import { useBuyOffers } from "./utils/offers";

export const Testing = () => {
  const x = useBuyOffers();
  const data = createMemo(() => x.data);

  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <Show when={x.isSuccess}>
          <For each={data()?.offers}>
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
