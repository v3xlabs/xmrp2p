/* eslint-disable no-restricted-syntax */
import type { Address } from "ox/Address";
import type { Provider } from "ox/Provider";

import type { OfferLike } from "../domain/offer";
import { getBuyOffer } from "../public/getBuyOffer";
import { getSellOffer } from "../public/getSellOffer";
import { listBuyOffers } from "../public/listBuyOffers";
import { listSellOffers } from "../public/listSellOffers";

const DEFAULT_PAGE_SIZE = 100n;

export type EvmReadClient = {
    provider: Provider;
    contractAddress: Address;
};

export const createEvmReadClient = ({
    provider,
    contractAddress,
}: EvmReadClient): EvmReadClient => ({
    provider,
    contractAddress,
});

export const listBuyOffersPage = async ({
    client,
    offset,
    count = DEFAULT_PAGE_SIZE,
}: {
    client: EvmReadClient;
    offset: bigint;
    count?: bigint;
}): Promise<OfferLike[]> => {
    const offers = await listBuyOffers({
        provider: client.provider,
        contractAddress: client.contractAddress,
        offset,
        count,
    });

    return offers as OfferLike[];
};

export const listSellOffersPage = async ({
    client,
    offset,
    count = DEFAULT_PAGE_SIZE,
}: {
    client: EvmReadClient;
    offset: bigint;
    count?: bigint;
}): Promise<OfferLike[]> => {
    const offers = await listSellOffers({
        provider: client.provider,
        contractAddress: client.contractAddress,
        offset,
        count,
    });

    return offers as OfferLike[];
};

export const getBuyOfferById = async ({
    client,
    id,
}: {
    client: EvmReadClient;
    id: bigint;
}): Promise<OfferLike> => {
    const offer = await getBuyOffer({
        provider: client.provider,
        contractAddress: client.contractAddress,
        id,
    });

    return offer as OfferLike;
};

export const getSellOfferById = async ({
    client,
    id,
}: {
    client: EvmReadClient;
    id: bigint;
}): Promise<OfferLike> => {
    const offer = await getSellOffer({
        provider: client.provider,
        contractAddress: client.contractAddress,
        id,
    });

    return offer as OfferLike;
};

export const filterOffersManagedBy = ({
    offers,
    manager,
}: {
    offers: readonly OfferLike[];
    manager: Address;
}): OfferLike[] => {
    const normalizedManager = manager.toLowerCase();

    return offers.filter(offer => offer.manager.toLowerCase() === normalizedManager);
};
