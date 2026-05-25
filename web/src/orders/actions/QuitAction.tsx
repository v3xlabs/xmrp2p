import classnames from "classnames";
import { CgSpinner } from "solid-icons/cg";
import { type Component, Show } from "solid-js";

import { useApp } from "../../hooks/useApp";
import { useQuitOrder } from "../../hooks/useQuitOrder";
import type { StoredOrderKeys } from "../../utils/keyStore";
import { ActionFeedback } from "./ActionFeedback";

export const QuitAction: Component<{
  offer_id: bigint;
  storedKeys: StoredOrderKeys;
  label: string;
}> = (props) => {
  const { chainId } = useApp();
  const { simulation, write } = useQuitOrder(() => ({
    offer_id: props.offer_id,
    privateSpendKey: BigInt(props.storedKeys.privateSpendKey),
    privateViewKey: BigInt(props.storedKeys.privateViewKey),
  }));

  return (
    <div class="space-y-2">
      <button
        class={classnames("btn w-full py-2 text-sm border border-(--thorin-orange-primary) text-(--thorin-orange-primary)")}
        disabled={!simulation.data || write.isPending}
        onClick={() => write.mutate()}
      >
        <Show when={write.isPending} fallback={props.label}>
          <CgSpinner class="animate-spin inline mr-1" />
          Quitting...
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
