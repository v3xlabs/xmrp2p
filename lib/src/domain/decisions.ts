import { OFFER_STATE, type OfferLike, type OfferSide, type OfferState } from "./offer";

export const shouldCancelOpenOffer = ({
    stop,
    close,
    hookDecision,
}: {
    stop: boolean;
    close: boolean;
    hookDecision?: boolean;
}): boolean => stop || close || hookDecision === true;

export const decideTakenOfferAction = ({
    offer,
    side,
    now,
    hasConfirmedXmrDeposit,
    t0SafetyMarginSeconds,
    confirmationMarginSeconds,
    readyHookResult,
    refundHookResult,
    initialSeenState,
}: {
    offer: Pick<OfferLike, "state" | "t0" | "t1">;
    side: OfferSide;
    now: number;
    hasConfirmedXmrDeposit: boolean;
    t0SafetyMarginSeconds: number;
    confirmationMarginSeconds: number;
    readyHookResult?: boolean;
    refundHookResult?: boolean;
    initialSeenState?: OfferState;
}): "none" | "claim" | "claimDeposit" | "refund" | "ready" | "transferXmr" => {
    const t0 = Number(offer.t0);
    const t1 = Number(offer.t1);

    if (side === "xmr") {
        if (now > t0 && now < t1) {
            return "claim";
        }

        if (initialSeenState === OFFER_STATE.OPEN && (t0 - now) > (t0SafetyMarginSeconds + confirmationMarginSeconds)) {
            return "transferXmr";
        }

        if (now > t1) {
            return "claimDeposit";
        }

        return "none";
    }

    if (side === "evm") {
        if (now > t1 || (!hasConfirmedXmrDeposit && (t0 - now) < t0SafetyMarginSeconds)) {
            return "refund";
        }

        if (hasConfirmedXmrDeposit && readyHookResult !== false) {
            return "ready";
        }

        if (!hasConfirmedXmrDeposit && refundHookResult === true) {
            return "refund";
        }

        return "none";
    }

    return "none";
};
