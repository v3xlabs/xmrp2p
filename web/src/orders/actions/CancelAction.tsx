import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import { type Component, Show } from "solid-js";

import { useApp } from "../../hooks/useApp";
import { useCancelOrder } from "../../hooks/useCancelOrder";
import { ActionFeedback } from "./ActionFeedback";

export const CancelAction: Component<{
  offer_id: bigint;
}> = (props) => {
  const { chainId } = useApp();
  const { simulation, write } = useCancelOrder(() => props.offer_id);

  return (
    <div class="space-y-2">
      <button
        class={classnames("btn w-full py-2 text-sm border border-(--thorin-red-primary) text-(--thorin-red-primary)")}
        disabled={!simulation.data || write.isPending}
        onClick={() => write.mutate()}
      >
        <Show when={write.isPending} fallback="Cancel Order">
          <CgSpinner class="animate-spin inline mr-1" />
          Cancelling...
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
