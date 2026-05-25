import { createQuery } from "@tanstack/solid-query";
import { useChains } from "@wagmi/solid";
import { waitForTransactionReceipt } from "@wagmi/solid/actions";
import { type Component, createMemo, For, Show } from "solid-js";
import type { Hash } from "viem";

import { config } from "../../config";

const BLOCKSCOUT_EXPLORERS: Record<number, string> = {
  1: "https://eth.blockscout.com",
  11_155_111: "https://eth-sepolia.blockscout.com",
  560_048: "https://eth-hoodi.blockscout.com",
};

export const ActionFeedback: Component<{
  simulationIsError: boolean;
  writeError: Error | null;
  writeHash?: Hash;
  writeIsSuccess: boolean;
  chainId?: number;
}> = (props) => {
  const chains = useChains();
  const chain = createMemo(() => chains().find(candidate => candidate.id === props.chainId));

  const explorerLinks = createMemo(() => {
    const hash = props.writeHash;

    if (!hash) return [];

    const links: { name: string; url: string; }[] = [];
    const defaultExplorer = chain()?.blockExplorers?.default;

    if (defaultExplorer) {
      links.push({ name: defaultExplorer.name, url: `${defaultExplorer.url}/tx/${hash}` });
    }

    const blockscoutUrl = props.chainId ? BLOCKSCOUT_EXPLORERS[props.chainId] : undefined;

    if (blockscoutUrl && defaultExplorer?.url !== blockscoutUrl) {
      links.push({ name: "Blockscout", url: `${blockscoutUrl}/tx/${hash}` });
    }

    return links;
  });

  const receipt = createQuery(() => {
    const hash = props.writeHash;
    const chainId = props.chainId;

    return {
      queryKey: ["tx", "receipt", chainId ?? 0, hash ?? "0x"],
      queryFn: () => waitForTransactionReceipt(config, {
        hash: hash!,
        chainId: chainId as never,
      }),
      enabled: !!hash && !!chainId,
    };
  });

  const isAwaitingReceipt = createMemo(() => !!props.writeHash && !receipt.isSuccess && !receipt.isError);

  return (
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
      <Show when={props.writeHash || props.writeIsSuccess}>
        <div class="text-sm text-(--thorin-blue-primary) bg-(--thorin-blue-surface) rounded p-3 space-y-3">
          <div class="flex items-center justify-between gap-2">
            <span class="font-medium">
              <Show when={receipt.isSuccess} fallback="Confirming...">
                Transaction confirmed
              </Show>
            </span>
            <Show when={explorerLinks().length > 0}>
              <div class="flex items-center gap-1.5">
                <For each={explorerLinks()}>
                  {link => (
                    <a
                      href={link.url}
                      target="_blank"
                      rel="noreferrer"
                      title={`View on ${link.name}`}
                      aria-label={`View transaction on ${link.name}`}
                      class="grid h-7 w-7 place-items-center rounded-full border border-(--thorin-border) bg-(--thorin-background-primary) text-xs font-bold text-(--thorin-blue-primary) hover:bg-(--thorin-background-secondary)"
                    >
                      {link.name.slice(0, 1)}
                    </a>
                  )}
                </For>
              </div>
            </Show>
          </div>

          <div class="h-3 overflow-hidden rounded-sm bg-(--thorin-background-primary)">
            <div
              class="h-full rounded-sm bg-(--thorin-blue-primary)"
              classList={{ "tx-progress-pending": isAwaitingReceipt(), "w-full": receipt.isSuccess }}
            />
          </div>

          <Show when={receipt.isError}>
            <div class="text-xs text-(--thorin-orange-primary)">
              Transaction was submitted, but confirmation status could not be loaded yet.
            </div>
          </Show>
        </div>
      </Show>
    </>
  );
};
