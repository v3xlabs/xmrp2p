/* @refresh reload */
import "./index.css";

import { QueryClientProvider } from "@tanstack/solid-query";
import { WagmiProvider } from "@wagmi/solid";
import { render } from "solid-js/web";

import { App } from "./App.tsx";
import { config, queryClient } from "./config.ts";

const root = document.querySelector("#root");

declare global {
  interface BigInt {
    toJSON: () => string;
  }
}

BigInt.prototype.toJSON = function () {
  return this.toString();
};

render(() => (
  <WagmiProvider config={config}>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </WagmiProvider>
), root!);
