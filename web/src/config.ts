/* eslint-disable no-restricted-syntax */
import { QueryClient } from "@tanstack/solid-query";
import { createConfig, http } from "@wagmi/solid";
import { mainnet, sepolia } from "@wagmi/solid/chains";

export const queryClient = new QueryClient();

export const config = createConfig({
    chains: [mainnet, sepolia],
    transports: {
        [mainnet.id]: http(),
        [sepolia.id]: http(),
    },
});
