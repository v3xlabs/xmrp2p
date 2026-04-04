import type { Address, Provider } from "ox";

export type ContractRead<T = object> = {
    provider: Provider.Provider;
    contractAddress: Address.Address;
} & T;

export type ContractWriteParameters<T = object> = {
    contractAddress: Address.Address;
} & T;
