import { FaSolidCheck, FaSolidCopy } from "solid-icons/fa";
import { type Component, createSignal, Show } from "solid-js";

export const KeyDisplay: Component<{
  label: string;
  value: string;
  mono?: boolean;
}> = (props) => {
  const [copied, setCopied] = createSignal(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(props.value);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div class="space-y-1">
      <div class="text-xs text-(--thorin-text-secondary) font-medium">{props.label}</div>
      <div class="flex items-center gap-1">
        <code class="text-xs bg-(--thorin-background-secondary) border border-(--thorin-border) rounded px-2 py-1 break-all flex-1 select-all">
          {props.value}
        </code>
        <button
          class="btn p-1.5 shrink-0"
          onClick={handleCopy}
          title="Copy to clipboard"
        >
          <Show when={copied()} fallback={<FaSolidCopy class="w-3 h-3" />}>
            <FaSolidCheck class="w-3 h-3 text-(--thorin-green-primary)" />
          </Show>
        </button>
      </div>
    </div>
  );
};
