/* eslint-disable no-restricted-syntax */
import type { Provider as OxProvider } from "ox/Provider";
import {
    createEvmReadClient,
    decideTakenOfferAction,
    getOfferSide,
    getOfferState,
    listBuyOffersPage,
    listSellOffersPage,
    OFFER_STATE,
    type OfferLike,
    type OfferState,
} from "xmrp2p";
import { deriveEvmAccountFromRootSeed } from "xmrp2p";

import type { AppConfig } from "./config.js";
import { selectProvider } from "./evmProvider.js";
import { logEvent } from "./logger.js";

const OFFERS_PAGE_SIZE = 100n;

type RunnerAction =
  | "none"
  | "claim"
  | "claimDeposit"
  | "refund"
  | "ready"
  | "transferXmr";

const parseRevertReason = (error: unknown): string => {
    if (!(error instanceof Error)) return String(error);

    const match = error.message.match(/execution reverted(?::\s*(.*))?$/i);

    if (!match) return error.message;

    return match[1]?.trim().length
        ? `execution reverted (${match[1].trim()})`
        : "execution reverted";
};

export const createRunner = ({
    config,
    providers,
}: {
    config: AppConfig;
    providers: OxProvider[];
}) => {
    let tick = 0;
    const initialSeenState = new Map<string, OfferState>();

    const managedAccounts = Array.from({ length: config.MAX_ACTIVE }, (_, accountIndex) =>
        deriveEvmAccountFromRootSeed({
            rootSeed: config.ROOT_SEED,
            accountIndex,
        }),
    );

    const managedAddressSet = new Set(managedAccounts.map(account => account.address.toLowerCase()));

    const classifyAction = ({
        offer,
    }: {
        offer: OfferLike;
    }): RunnerAction => {
        const state = getOfferState(offer);

        if (state === OFFER_STATE.TAKEN) {
            return decideTakenOfferAction({
                offer,
                side: getOfferSide(offer),
                now: Math.floor(Date.now() / 1000),
                hasConfirmedXmrDeposit: false,
                t0SafetyMarginSeconds: config.T0_SAFETY_MARGIN,
                confirmationMarginSeconds: config.CONFIRMATION_MARGIN,
                initialSeenState: initialSeenState.get(offer.id.toString()),
            });
        }

        if (state === OFFER_STATE.READY && getOfferSide(offer) === "evm") {
            return Math.floor(Date.now() / 1000) > Number(offer.t1)
                ? "refund"
                : "none";
        }

        return "none";
    };

    const loadOffers = async ({
        client,
    }: {
        client: ReturnType<typeof createEvmReadClient>;
    }): Promise<OfferLike[]> => {
        const primary = config.ROLE === "buyer" ? "buy" : "sell";

        try {
            return config.ROLE === "buyer"
                ? await listBuyOffersPage({ client, offset: 0n, count: OFFERS_PAGE_SIZE })
                : await listSellOffersPage({ client, offset: 0n, count: OFFERS_PAGE_SIZE });
        }
        catch (primaryError) {
            try {
                if (config.ROLE === "buyer") {
                    return await listSellOffersPage({ client, offset: 0n, count: OFFERS_PAGE_SIZE });
                }

                return await listBuyOffersPage({ client, offset: 0n, count: OFFERS_PAGE_SIZE });
            }
            catch (secondaryError) {
                const primaryReason = parseRevertReason(primaryError);
                const secondaryReason = parseRevertReason(secondaryError);

                throw new Error(
                    `Unable to load offers (primary=${primary}, contract=${config.CONTRACT}). `
                    + `Primary error: ${primaryReason}. Secondary error: ${secondaryReason}.`,
                );
            }
        }
    };

    const runTick = async (): Promise<void> => {
        tick += 1;
        const provider = selectProvider({ providers: [...providers], tick });
        const client = createEvmReadClient({
            provider,
            contractAddress: config.CONTRACT,
        });

        logEvent({
            name: "bot.tick",
            at: new Date().toISOString(),
            detail: `tick=${tick}`,
        });

        const offers = await loadOffers({ client });
        const owned = offers.filter(offer => managedAddressSet.has(offer.manager.toLowerCase()));

        for (const offer of owned) {
            const offerId = offer.id.toString();
            const state = getOfferState(offer);

            if (!initialSeenState.has(offerId)) {
                initialSeenState.set(offerId, state);
            }

            logEvent({
                name: "offer.observed",
                at: new Date().toISOString(),
                offerId: offer.id,
                detail: `state=${state}`,
            });

            const action = classifyAction({ offer });

            if (action !== "none") {
                logEvent({
                    name: "offer.action.requested",
                    at: new Date().toISOString(),
                    offerId: offer.id,
                    action,
                });
            }

            if (state !== OFFER_STATE.OPEN && state !== OFFER_STATE.TAKEN && state !== OFFER_STATE.READY) {
                initialSeenState.delete(offerId);
            }
        }
    };

    const start = (): void => {
        logEvent({
            name: "bot.started",
            at: new Date().toISOString(),
            detail: `role=${config.ROLE} maxActive=${config.MAX_ACTIVE}`,
        });

        void runTick().catch((error: unknown) => {
            logEvent({
                name: "offer.action.failed",
                at: new Date().toISOString(),
                detail: "initial tick failed",
                error: parseRevertReason(error),
            });
        });

        setInterval(() => {
            void runTick().catch((error: unknown) => {
                logEvent({
                    name: "offer.action.failed",
                    at: new Date().toISOString(),
                    detail: "tick failed",
                    error: parseRevertReason(error),
                });
            });
        }, config.LOOP_DELAY * 1000);
    };

    return { start };
};
