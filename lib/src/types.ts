import { Address } from "ox/Address";
import type { Provider } from "ox/Provider";

export type ContractRead<T = object> = {
    provider: Provider;
    contractAddress: Address;
} & T;

export type ContractWriteParameters<T = object> = {
    contractAddress: Address;
} & T;
