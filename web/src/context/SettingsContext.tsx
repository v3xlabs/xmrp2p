import { type Component, createContext, createEffect, type JSX, useContext } from "solid-js";
import { createStore } from "solid-js/store";

const STORAGE_KEYS = {
  devnet: "xmrp2p:devnet-mode",
  testnet: "xmrp2p:testnet-mode",
  mainnet: "xmrp2p:mainnet-mode",
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
  modes: {
    devnets: boolean;
    testnets: boolean;
    mainnets: boolean;
  };
  setModes: (v: {
    devnets: boolean;
    testnets: boolean;
    mainnets: boolean;
  }) => void;
}

const SettingsContext = createContext<SettingsContextValue>();

export const SettingsProvider: Component<{ children: JSX.Element; }> = (props) => {
  const [modes, setModes] = createStore({
    devnets: readBool(STORAGE_KEYS.devnet, import.meta.env.MODE === "development"),
    testnets: readBool(STORAGE_KEYS.testnet, true),
    mainnets: readBool(STORAGE_KEYS.mainnet, import.meta.env.MODE === "production"),
  });

  createEffect(() => {
    localStorage.setItem(STORAGE_KEYS.devnet, String(modes.devnets));
    localStorage.setItem(STORAGE_KEYS.testnet, String(modes.testnets));
    localStorage.setItem(STORAGE_KEYS.mainnet, String(modes.mainnets));
  });

  return (
    <SettingsContext.Provider value={{ modes, setModes }}>
      {props.children}
    </SettingsContext.Provider>
  );
};

export const useSettings = (): SettingsContextValue => {
  const ctx = useContext(SettingsContext);

  if (!ctx) throw new Error("useSettings must be used within a SettingsProvider");

  return ctx;
};
