import { CgSpinner } from "solid-icons/cg";
import { type Component, Show } from "solid-js";

import { useReadyOrder } from "../../hooks/useReadyOrder";
import { ActionFeedback } from "./ActionFeedback";

export const ReadyAction: Component<{
  offer_id: bigint;
}> = (props) => {
  const { simulation, write } = useReadyOrder(() => props.offer_id);

  return (
    <div class="space-y-2">
      <button
        class="btn-primary w-full py-2 btn-lg"
        disabled={!simulation.data || write.isPending}
        onClick={() => write.mutate()}
      >
        <Show when={write.isPending} fallback="Confirm XMR Received">
          <CgSpinner class="animate-spin inline mr-1" />
          Confirming...
        </Show>
      </button>
      <ActionFeedback
        simulationIsError={simulation.isError}
        writeError={write.error}
        writeIsSuccess={write.isSuccess}
      />
    </div>
  );
};
