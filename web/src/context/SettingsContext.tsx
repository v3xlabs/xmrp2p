import { anvil, mainnet, sepolia } from "@wagmi/solid/chains";
import { type Component, createContext, createEffect, createMemo, createSignal, type JSX, useContext } from "solid-js";
import type { Chain } from "viem";

const STORAGE_KEYS = {
  devnet: "xmrp2p:devnet-mode",
  testnet: "xmrp2p:testnet-mode",
} as const;

const readBool = (key: string, fallback: boolean): boolean => {
  try {
    const stored = localStorage.getItem(key);

    if (stored === null) return fallback;

    return stored === "true";
  }
  catch {
    return fallback;
  }
};

interface SettingsContextValue {
  devnetMode: () => boolean;
  setDevnetMode: (v: boolean) => void;
  testnetMode: () => boolean;
  setTestnetMode: (v: boolean) => void;
  availableChains: () => Chain[];
}

const SettingsContext = createContext<SettingsContextValue>();

export const SettingsProvider: Component<{ children: JSX.Element; }> = (props) => {
  const [devnetMode, setDevnetMode] = createSignal(
    readBool(STORAGE_KEYS.devnet, import.meta.env.MODE === "development"),
  );
  const [testnetMode, setTestnetMode] = createSignal(
    readBool(STORAGE_KEYS.testnet, false),
  );

  createEffect(() => {
    localStorage.setItem(STORAGE_KEYS.devnet, String(devnetMode()));
  });

  createEffect(() => {
    localStorage.setItem(STORAGE_KEYS.testnet, String(testnetMode()));
  });

  const availableChains = createMemo((): Chain[] => {
    const chains: Chain[] = [mainnet];

    if (devnetMode()) chains.push(anvil);

    if (testnetMode()) chains.push(sepolia);

    return chains;
  });

  const value: SettingsContextValue = {
    devnetMode,
    setDevnetMode,
    testnetMode,
    setTestnetMode,
    availableChains,
  };

  return (
    <SettingsContext.Provider value={value}>
      {props.children}
    </SettingsContext.Provider>
  );
};

export const useSettings = (): SettingsContextValue => {
  const ctx = useContext(SettingsContext);

  if (!ctx) throw new Error("useSettings must be used within a SettingsProvider");

  return ctx;
};
