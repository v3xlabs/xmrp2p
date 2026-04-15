/* eslint-disable no-restricted-syntax */
import { openlv } from "@openlv/connector";
import { QueryClient } from "@tanstack/solid-query";
import { createConfig, http } from "@wagmi/solid";
import { anvil, hoodi, mainnet, sepolia } from "@wagmi/solid/chains";

export const queryClient = new QueryClient();

export const CONTRACT_ADDRESS: Record<number, string | undefined> = {
  [mainnet.id]: undefined,
  [sepolia.id]: "0x4fd57ad6fF61FE7455772fB49647a8fa3aA2C33A",
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
