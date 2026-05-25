import { CgSpinner } from "solid-icons/cg";
import { type Component, Show } from "solid-js";

import { useApp } from "../../hooks/useApp";
import type { Offer } from "../../hooks/useOffers";
import { useTakeOrder } from "../../hooks/useTakeOrder";
import { ActionFeedback } from "./ActionFeedback";

export const TakeAction: Component<{
  offer: Offer;
}> = (props) => {
  const { chainId } = useApp();
  const { simulation, write } = useTakeOrder(() => props.offer);

  return (
    <div class="space-y-2">
      <button
        class="btn-primary w-full py-2 btn-lg"
        disabled={!simulation.data || write.isPending}
        onClick={() => write.mutate()}
      >
        <Show when={write.isPending} fallback="Take Order">
          <CgSpinner class="animate-spin inline mr-1" />
          Taking...
        </Show>
      </button>
      <ActionFeedback
        simulationIsError={simulation.isError}
        writeError={write.error}
        writeHash={write.data}
        writeIsSuccess={write.isSuccess}
        chainId={chainId()}
      />
    </div>
  );
};
