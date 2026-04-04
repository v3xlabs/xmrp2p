/* eslint-disable no-restricted-syntax */
export const OFFER_STATE = {
    INVALID: 0,
    OPEN: 1,
    TAKEN: 2,
    CANCELLED: 3,
    REFUNDED: 4,
    READY: 5,
    CLAIMED: 6,
    UPDATING: 7,
} as const;

export const OFFER_TYPE = {
    BUY: 1,
    SELL: 2,
} as const;

export type OfferState = (typeof OFFER_STATE)[keyof typeof OFFER_STATE];

export type OfferSide = "evm" | "xmr" | "unknown";

export type OfferLike = {
    type_: number | bigint;
    state: number | bigint;
    evmPrivateSpendKey: bigint;
    xmrPrivateSpendKey: bigint;
    id: bigint;
    owner: `0x${string}`;
    manager: `0x${string}`;
    counterparty: `0x${string}`;
    funded: boolean;
    maxamount: bigint;
    price: bigint;
    oracleRatio: bigint;
    oracleOffset: bigint;
    minxmr: bigint;
    maxxmr: bigint;
    maxprice: bigint;
    minprice: bigint;
    deposit: bigint;
    lastupdate: bigint;
    blockTaken: bigint;
    evmPublicSpendKey: bigint;
    evmPublicViewKey: bigint;
    evmPrivateViewKey: bigint;
    xmrPublicSpendKey: bigint;
    xmrPrivateViewKey: bigint;
    index: bigint;
    finalprice: bigint;
    takerDeposit: bigint;
    finalxmr: bigint;
    t0: bigint;
    t1: bigint;
    xmrPublicMsgKey: bigint;
    evmPublicMsgKey: bigint;
};

const toNumber = (value: number | bigint): number =>
    (typeof value === "bigint" ? Number(value) : value);

export const getOfferState = (offer: Pick<OfferLike, "state">): OfferState =>
    toNumber(offer.state) as OfferState;

export const getOfferSide = (offer: Pick<OfferLike, "evmPrivateSpendKey" | "xmrPrivateSpendKey">): OfferSide => {
    if (offer.evmPrivateSpendKey !== 0n) return "evm";

    if (offer.xmrPrivateSpendKey !== 0n) return "xmr";

    return "unknown";
};
