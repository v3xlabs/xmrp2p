import { createQuery } from "@tanstack/solid-query";
import { type Component, Show, Suspense } from "solid-js";
import type { Address } from "viem";

import { queryKeys } from "./queryKeys";
import { useEnsName } from "./useEnstate";

export const truncateAddress = (address: string | Address | undefined) => (address ? address.slice(0, 5) + "..." + address.slice(-3) : undefined);

const Addry = (props: { address: string | Address | undefined; }) => (
  <>{truncateAddress(props.address)}</>
);

export const Addr: Component<{ address: string | Address | undefined; }> = (props) => {
  const ensData = createQuery(() => ({ queryKey: queryKeys.address(props.address ?? ""), queryFn: () => useEnsName(props.address), enabled: !!props.address }));

  return (
    <span>
      <Suspense fallback={<Addry address={props.address} />}>
        <Show when={ensData.isSuccess && ensData.data?.name} fallback={<Addry address={props.address} />}>
          {ensData.data!.name}
        </Show>
      </Suspense>
    </span>
  );
};
