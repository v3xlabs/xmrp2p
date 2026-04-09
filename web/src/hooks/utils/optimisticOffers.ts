import type { InfiniteData } from "@tanstack/solid-query";

import { queryClient } from "../../config";
import type { Offer } from "../../utils/offers";

type OffersInfiniteData = InfiniteData<Offer[], number>;

export const updateOfferInCache = (
  queryKey: readonly unknown[],
  offerId: bigint,
  patch: Partial<Offer>,
) => {
  queryClient.setQueryData<OffersInfiniteData>(
    queryKey,
    (old) => {
      if (!old) return old;

      return {
        ...old,
        pages: old.pages.map(page =>
          page.map(offer =>
            (offer.id === offerId ? { ...offer, ...patch } : offer), // eslint-disable-line no-restricted-syntax
          ),
        ),
      };
    },
  );
};
