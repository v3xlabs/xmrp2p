/* eslint-disable no-restricted-syntax */
import { getOffers } from "xmrp2p";

export type Offer = Awaited<ReturnType<typeof getOffers>>[number];

type OfferTuple = readonly [
  bigint,
  number,
  number,
  `0x${string}`,
  `0x${string}`,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
  bigint,
];

const PRICE_SCALE = 10n ** 18n;

export const decodeOfferTuple = (offer: OfferTuple): Offer => ({
  id: offer[0],
  kind: offer[1],
  state: offer[2],
  owner: offer[3],
  counterparty: offer[4],
  amount: offer[5],
  deposit: offer[6],
  price: offer[7],
  lastupdate: offer[8],
  blockTaken: offer[9],
  evmPublicSpendKey: offer[10],
  evmPrivateSpendKey: offer[11],
  evmPublicViewKey: offer[12],
  evmPrivateViewKey: offer[13],
  xmrPublicSpendKey: offer[14],
  xmrPrivateSpendKey: offer[15],
  xmrPrivateViewKey: offer[16],
  t0: offer[17],
  t1: offer[18],
});

export const getOfferXmrAmount = (offer: Pick<Offer, "amount" | "price">) =>
  offer.amount * offer.price / PRICE_SCALE;
