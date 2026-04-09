import { type Component, Show } from "solid-js";

export const ActionFeedback: Component<{
  simulationIsError: boolean;
  writeError: Error | null;
  writeIsSuccess: boolean;
}> = props => (
  <>
    <Show when={props.writeError}>
      {error => (
        <div class="text-xs text-(--thorin-red-primary) bg-(--thorin-red-surface) rounded p-2 break-all">
          {error().message ?? "Transaction failed"}
        </div>
      )}
    </Show>
    <Show when={props.simulationIsError}>
      <div class="text-xs text-(--thorin-orange-primary) bg-(--thorin-orange-surface) rounded p-2 break-all">
        This action cannot be performed right now
      </div>
    </Show>
    <Show when={props.writeIsSuccess}>
      <div class="text-xs text-(--thorin-green-primary) bg-(--thorin-green-surface) rounded p-2">
        Transaction submitted successfully
      </div>
    </Show>
  </>
);
