const STORAGE_KEY = "xmrp2p:order-keys";

export interface StoredOrderKeys {
  offer_id: string;
  chain_id: number;
  wallet_address: string;
  role: "evm" | "xmr";
  mnemonic: string;
  privateSpendKey: string;
  privateViewKey: string;
  publicSpendKey: string;
  publicViewKey: string;
}

export const getAllStoredKeys = (): StoredOrderKeys[] => {
  const raw = localStorage.getItem(STORAGE_KEY);

  if (!raw) return [];

  try {
    return JSON.parse(raw) as StoredOrderKeys[];
  }
  catch {
    return [];
  }
};

export const getStoredKeys = (
  chainId: number,
  offerId: bigint,
  walletAddress: string,
): StoredOrderKeys | null => {
  const all = getAllStoredKeys();
  const addr = walletAddress.toLowerCase();

  return all.find(
    k => k.chain_id === chainId
      && k.offer_id === offerId.toString()
      && k.wallet_address.toLowerCase() === addr,
  ) ?? null;
};

export const storeOrderKeys = (keys: StoredOrderKeys): void => {
  const all = getAllStoredKeys();
  const addr = keys.wallet_address.toLowerCase();
  const idx = all.findIndex(
    k => k.chain_id === keys.chain_id
      && k.offer_id === keys.offer_id
      && k.wallet_address.toLowerCase() === addr,
  );

  if (idx === -1) {
    all.push(keys);
  }
  else {
    all[idx] = keys;
  }

  localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
};
