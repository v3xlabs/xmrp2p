import { formatUnits } from "viem";
import { computeEscrowWallet, encodeMoneroAddress } from "xmrp2p";

import type { Offer } from "../hooks/useOffers";

const ED25519_L = 2n ** 252n + 27_742_317_777_372_353_535_851_937_790_883_648_493n;

export const combinePrivateKeys = (key1: bigint, key2: bigint): bigint =>
  (key1 + key2) % ED25519_L;

export const toMoneroKeyHex = (key: bigint): string => {
  const hex = key.toString(16).padStart(64, "0");
  const pairs: string[] = [];

  for (let i = 0; i < hex.length; i += 2) {
    pairs.push(hex.slice(i, i + 2));
  }

  return pairs.reverse().join("");
};

export const getXmrAmount = (offer: Offer): string => {
  const piconeros = offer.amount * offer.price / 10n ** 18n;

  return formatUnits(piconeros, 12);
};

export const getEscrowAddress = (offer: Offer): string | null => {
  if (
    !offer.evmPublicSpendKey
    || !offer.evmPublicViewKey
    || !offer.xmrPublicSpendKey
    || !offer.xmrPrivateViewKey
  ) {
    return null;
  }

  try {
    const { publicSpendKey, publicViewKey } = computeEscrowWallet(
      {
        evmPublicViewKey: offer.evmPublicViewKey,
        xmrPrivateViewKey: offer.xmrPrivateViewKey,
        evmPublicSpendKey: offer.evmPublicSpendKey,
        xmrPublicSpendKey: offer.xmrPublicSpendKey,
      },
    );

    return encodeMoneroAddress(publicSpendKey, publicViewKey, true);
  }
  catch (error) {
    console.log("error getting escrow address for offer", offer, error);

    return null;
  }
};

export const createMoneroPaymentUri = (
  address: string,
  xmrAmount: string,
): string =>
  `monero:${address}?address=${address}&tx_amount=${xmrAmount}`;

export const createMoneroViewUri = (
  address: string,
  privateViewKey: bigint,
  label: string,
  restoreHeight?: number,
): string => {
  const viewKeyHex = toMoneroKeyHex(privateViewKey);
  const params = new URLSearchParams({
    address,
    view_key: viewKeyHex,
    label,
  });

  if (restoreHeight != null && restoreHeight > 0) {
    params.set("height", String(restoreHeight));
  }

  return `monero_wallet:${address}?${params.toString()}`;
};

export const createMoneroWalletUri = (
  address: string,
  privateSpendKey: bigint,
  privateViewKey: bigint,
  label: string,
  restoreHeight?: number,
): string => {
  const spendKeyHex = toMoneroKeyHex(privateSpendKey);
  const viewKeyHex = toMoneroKeyHex(privateViewKey);
  const params = new URLSearchParams({
    address,
    spend_key: spendKeyHex,
    view_key: viewKeyHex,
    label,
  });

  if (restoreHeight != null && restoreHeight > 0) {
    params.set("height", String(restoreHeight));
  }

  return `monero_wallet:${address}?${params.toString()}`;
};

export const isEvmSide = (offer: Offer, userAddress: string | undefined): boolean => {
  if (!userAddress) return false;

  const addr = userAddress.toLowerCase();

  if (offer.kind === 1) return offer.owner.toLowerCase() === addr;

  return offer.counterparty.toLowerCase() === addr;
};

export const isXmrSide = (offer: Offer, userAddress: string | undefined): boolean => {
  if (!userAddress) return false;

  const addr = userAddress.toLowerCase();

  if (offer.kind === 1) return offer.counterparty.toLowerCase() === addr;

  return offer.owner.toLowerCase() === addr;
};

export const isOwner = (offer: Offer, userAddress: string | undefined): boolean => {
  if (!userAddress) return false;

  return offer.owner.toLowerCase() === userAddress.toLowerCase();
};
