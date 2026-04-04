/* eslint-disable no-restricted-syntax */
import { openlv } from "@openlv/connector";
import { QueryClient } from "@tanstack/solid-query";
import { createConfig, http } from "@wagmi/solid";
import { localhost, mainnet, sepolia } from "@wagmi/solid/chains";

export const queryClient = new QueryClient();

export const CONTRACT_ADDRESS: Record<number, string | undefined> = {
    [mainnet.id]: undefined,
    [sepolia.id]: undefined,
    [localhost.id]: "0x5FbDB2315678afecb367f032d93F642f64180aa3",
};

export const config = createConfig({
    chains: [
        mainnet,
        sepolia,
        localhost,
    ],
    transports: {
        [mainnet.id]: http(),
        [sepolia.id]: http(),
        [localhost.id]: http("http://127.0.0.1:8545"),
    },
    connectors: [
        openlv(),
    ],
});
