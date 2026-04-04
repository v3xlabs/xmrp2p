import type { OfferLike } from "xmrp2p";

type BotEventName =
  | "bot.started"
  | "bot.tick"
  | "offer.observed"
  | "offer.action.requested"
  | "offer.action.failed";

type OfferAction =
  | "none"
  | "claim"
  | "claimDeposit"
  | "ready"
  | "refund"
  | "transferXmr";

type BotEvent = {
    name: BotEventName;
    at: string;
    accountIndex?: number;
    offerId?: bigint;
    action?: OfferAction;
    detail?: string;
    offer?: OfferLike;
    error?: string;
};

export const logEvent = (event: BotEvent): void => {
    const payload = {
        ...event,
        offerId: event.offerId?.toString(),
    };

    console.log(JSON.stringify(payload));
};
