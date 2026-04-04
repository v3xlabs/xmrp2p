import { createQuery } from "@tanstack/solid-query";
import { useChainId, useClient } from "@wagmi/solid";
import type { Provider as OxProvider } from "ox/Provider";
import { listBuyOffers, listSellOffers } from "xmrp2p";

import { CONTRACT_ADDRESS } from "./config";

export const Testing = () => {
  const client = useClient();
  const chainId = useChainId();
  const provider = client() as OxProvider;
  const x = createQuery(() => ({
    queryKey: ["orders"],
    queryFn: async () => {
      console.log("fetching offers");

      const offers = await listSellOffers({
        provider,
        contractAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
        // contractAddress: CONTRACT_ADDRESS[chainId()!] as `0x${string}`,
        offset: BigInt(0),
        count: BigInt(10),
      });

      const offersB = await listBuyOffers({
        provider,
        contractAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
        // contractAddress: CONTRACT_ADDRESS[chainId()!] as `0x${string}`,
        offset: BigInt(0),
        count: BigInt(10),
      });

      return { offers, offersB };
    },
    enabled: !!chainId() && !!client() && !!CONTRACT_ADDRESS[chainId()!],
  }));

  return (
    <div>
      hellllooo:
      {chainId()}
      {" "}
      {JSON.stringify(x.data, null, 2)}
    </div>
  );
};
