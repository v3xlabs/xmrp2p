import { CgSpinner } from "solid-icons/cg";
import { type Component, Show } from "solid-js";

import { useApp } from "../../hooks/useApp";
import { useClaimOrder } from "../../hooks/useClaimOrder";
import type { StoredOrderKeys } from "../../utils/keyStore";
import { ActionFeedback } from "./ActionFeedback";

export const ClaimAction: Component<{
  offer_id: bigint;
  storedKeys: StoredOrderKeys;
  label: string;
}> = (props) => {
  const { chainId } = useApp();
  const { simulation, write } = useClaimOrder(() => ({
    offer_id: props.offer_id,
    privateSpendKey: BigInt(props.storedKeys.privateSpendKey),
  }));

  return (
    <div class="space-y-2">
      <button
        class="btn-primary w-full py-2 btn-lg"
        disabled={!simulation.data || write.isPending}
        onClick={() => write.mutate()}
      >
        <Show when={write.isPending} fallback={props.label}>
          <CgSpinner class="animate-spin inline mr-1" />
          Claiming...
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
