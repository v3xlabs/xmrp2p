/* eslint-disable no-restricted-syntax */
import { QueryClient } from "@tanstack/solid-query";
import { createConfig, http } from "@wagmi/solid";
import { localhost, mainnet, sepolia } from "@wagmi/solid/chains";

export const queryClient = new QueryClient();

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
});
