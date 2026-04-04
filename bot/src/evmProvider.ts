import { Provider, RpcTransport } from "ox";
import type { Provider as OxProvider } from "ox/Provider";

export const createProviderPool = (rpcUrls: string[]): OxProvider[] => {
    if (rpcUrls.length === 0) {
        throw new Error("At least one EVM RPC URL is required");
    }

    return rpcUrls.map(url => Provider.from(RpcTransport.fromHttp(url)));
};

export const selectProvider = ({
    providers,
    tick,
}: {
    providers: OxProvider[];
    tick: number;
}): OxProvider => {
    const provider = providers[tick % providers.length];

    if (!provider) {
        throw new Error("No provider available in pool");
    }

    return provider;
};
