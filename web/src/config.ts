/* eslint-disable no-restricted-syntax */
import { openlv } from "@openlv/connector";
import { QueryClient } from "@tanstack/solid-query";
import { createConfig, http } from "@wagmi/solid";
import { anvil, hoodi, mainnet, sepolia } from "@wagmi/solid/chains";

export const queryClient = new QueryClient();

export const CONTRACT_ADDRESS: Record<number, string | undefined> = {
  [mainnet.id]: undefined,
  [sepolia.id]: "0xad6871d44804288ba4393464c63544d6691d76ba",
  [anvil.id]: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
};

export const config = createConfig({
  chains: [
    // mainnet,
    sepolia,
    anvil,
    hoodi,
  ],
  transports: {
    // [mainnet.id]: http(),
    [sepolia.id]: http("https://sepolia.drpc.org"),
    [anvil.id]: http("http://127.0.0.1:8545"),
    [hoodi.id]: http("https://rpc.hoodi.ethpandaops.io"),
  },
  connectors: [
    openlv(),
  ],
});
