import { Address } from "ox/Address";
import { Provider } from "ox/Provider";

export type ContractCall<T = object> = {
    provider: Provider;
    contractAddress: Address;
} & T;
