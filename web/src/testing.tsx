import { createQuery } from "@tanstack/solid-query";
import { useChainId, useClient } from "@wagmi/solid";
import type { Provider as OxProvider } from "ox/Provider";
import { createMemo, For, Show, Suspense } from "solid-js";
import { listBuyOffers } from "xmrp2p";

import { CONTRACT_ADDRESS } from "./config";

export const Testing = () => {
  const client = useClient();
  const chainId = useChainId();
  const provider = client() as OxProvider;
  const x = createQuery(() => ({
    queryKey: ["orders"],
    queryFn: async () => {
      console.log("fetching offers");
      const contractAddress = CONTRACT_ADDRESS[chainId()!] as `0x${string}`;

      // const offers = await listSellOffers({
      //   provider,
      //   contractAddress,
      //   offset: BigInt(0),
      //   count: BigInt(10),
      // });

      console.log("yoink");

      try {
        const offers = await listBuyOffers({
          provider,
          contractAddress,
          offset: BigInt(0),
          count: BigInt(10),
        });

        console.log("SUCCESS");

        return { offers };
      }
      catch (error) {
        console.error(error);
      }

      return {};
    },
    // enabled: !!chainId() && !!client() && !!CONTRACT_ADDRESS[chainId()!],
  }));

  const data = createMemo(() => x.data);

  return (
    <div>
      hellllooo:
      {chainId()}
      {" "}
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
