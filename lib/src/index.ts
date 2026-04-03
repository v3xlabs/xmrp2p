import type { Address, Provider } from "ox";

export type ContractCall<T = object> = {
    provider: Provider.Provider;
    contractAddress: Address.Address;
} & T;
