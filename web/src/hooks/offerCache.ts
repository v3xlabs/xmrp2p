/* eslint-disable no-restricted-syntax */
import { queryClient } from "../config";
import { queryKeys } from "../utils/queryKeys";
import type { Offer } from "./offerCodec";

export type OffersPage = {
  offers: Offer[];
  hasMore: boolean;
};

type OffersInfiniteData = {
  pages: OffersPage[];
  pageParams: number[];
};

const repartitionOffers = (pages: OffersPage[], offers: Offer[]): OffersPage[] => {
  let cursor = 0;

  return pages.map((page) => {
    const nextCursor = cursor + page.offers.length;
    const nextPageOffers = offers.slice(cursor, nextCursor);

    cursor = nextCursor;

    return {
      ...page,
      offers: nextPageOffers,
    };
  });
};

const upsertOfferInPages = (pages: OffersPage[], offer: Offer): OffersPage[] => {
  if (pages.length === 0) return pages;

  const loadedOffers = pages.flatMap(page => page.offers);
  const existingIndex = loadedOffers.findIndex(entry => entry.id === offer.id);

  if (existingIndex !== -1) {
    const nextOffers = [...loadedOffers];

    if (offer.state === 0) {
      nextOffers.splice(existingIndex, 1);
    }
    else {
      nextOffers[existingIndex] = offer;
    }

    return repartitionOffers(pages, nextOffers);
  }

  if (offer.state === 0) return pages;

  const newestLoadedId = loadedOffers[0]?.id;

  if (newestLoadedId !== undefined && offer.id <= newestLoadedId) {
    return pages;
  }

  return repartitionOffers(pages, [offer, ...loadedOffers].slice(0, loadedOffers.length));
};

export const applyOfferToCaches = (chainId: number, offer: Offer) => {
  queryClient.setQueryData(queryKeys.offers.single(chainId, offer.id), () => offer);
  queryClient.setQueryData(queryKeys.offers.all(chainId), (stale: OffersInfiniteData | undefined) => {
    if (!stale) return stale;

    return {
      ...stale,
      pages: upsertOfferInPages(stale.pages, offer),
    };
  });
};

export const invalidateOfferCaches = async (chainId: number, offerId?: bigint) => {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: queryKeys.offers.all(chainId) }),
    offerId === undefined
      ? Promise.resolve()
      : queryClient.invalidateQueries({ queryKey: queryKeys.offers.single(chainId, offerId) }),
  ]);
};
