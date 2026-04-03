// SPDX-License-Identifier: MIT
//
// Copyright (c) 2025-2026  v1rtl
//

pragma solidity ^0.8.34;

import "./Enums.sol";

//
// Errors
//

/// Error raised when an address attempts to create a BuyOffer while there exists a FundingRequest for that same address.
/// The rationale is that if the address opens a BuyOffer then it has a balance which would have allowed to open a SellOffer.
/// So we disallow creating a BuyOffer unless the FundingRequest is removed, either voluntarily or because the SellOffer which
/// it funded has completed.
error ErrorBuyOfferNoCreationWhenActiveFundingRequestExists();

/// This error is raised when a BuyOffer is created or updated and the specified amount is below the minimum amount
/// configured in the contract for buy offers (MINIMUM_BUY_OFFER)
/// @param minimum the minimum acceptable amount
error ErrorBuyOfferAmountBelowMinimum(uint256 minimum);

/// This error is raised when a BuyOffer is created or updated and the specified amount is above the maximum amount
/// configured in the contract for buy offers (MAXIMUM_BUY_OFFER)
/// @param maximum the maximum acceptable amount
error ErrorBuyOfferAmountAboveMaximum(uint256 maximum);

/// This error is raised when a BuyOffer is updated and the specified state is not compatible with updates
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForUpdate(OfferState state);

/// This error is raised when a BuyOffer is created or updated with a price ratio while a fixed price was also specified
error ErrorBuyOfferNoPriceRatioWithFixedPrice();

/// This error is raised when a BuyOffer is created or updated with a price offset while a fixed price was also specified
error ErrorBuyOfferNoPriceOffsetWithFixedPrice();

/// Error raised when attempting to create or update a BuyOffer using a price oracle when no price oracle is configured
error ErrorBuyOfferNoPriceOracleDefined();

/// Error raised when attempting to reference a non existent BuyOffer.
error ErrorBuyOfferUnknown();

/// Error raised when attempting to create or update a BuyOffer with no fixed price and with an oracleRatio value of 0.
error ErrorBuyOfferInvalidOraclePriceRatio();

/// Error raised when attempting to update a BuyOffer from an address which is neither the owner nor the optionally configured manager
error ErrorBuyOfferInvalidCallerForUpdate();

/// Error raised when an operation that can only be performed by the buy offer owner is called from another address
error ErrorBuyOfferNotOwner();

/// Error raised when decreasing the maximum amount of a Buy Offer and the delta amount could not be sent back to the offer owner
error ErrorBuyOfferUnableToSendAmountDelta();

/// This error is raised when a the creation of a BuyOffer is requested with a public spend key which has
/// already been associated with an offer handled by this instance of the contract. This is a security measure
/// to ensure that a public spend key whose private spend key was exposed, either via a call to claim or refund,
/// is not reused.
error ErrorBuyOfferPublicSpendKeyAlreadyUsed();

/// Error raised when the price specified in a take call is below the lower acceptable price
/// @param price the price in the take call
/// @param minprice the lower acceptable price
error ErrorBuyOfferPriceTooLow(uint256 price, uint256 minprice);

/// Error raised when the dynamic price is negative price during a buy offer price estimation
error ErrorBuyOfferNegativeDynamicPrice();

/// Error raised when the price returned by the price feed oracle is too old with respect to the contract's XMREVMMaxage parameter
error ErrorBuyOfferOraclePriceTooOld();

/// Error raised when the amount of XMR specified in a take call is below the minimum amount the buy offer owner is willing to buy
/// @param amount the amount of XMR specified in the take call
/// @param minamount the minimum amount of XMR the buy offer owner is willing to acquire
error ErrorBuyOfferXMRAmountTooLow(uint256 amount, uint256 minamount);

/// Error raised when a take operation is funded by a FundingRequest but the amount specified for the take doesn't cover the funding fee
error ErrorBuyOfferAmountTooLowToCoverFundingFee();

/// Error raised when a take operation is attempted on an offer which is not in the OPEN state.
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForTake(OfferState state);

/// Error raised when a ready operation is attempted on an offer which is not in the TAKEN state.
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForReady(OfferState state);

/// Error raised when attempting to call ready on a Buy Offer after the t0 timestamp
error ErrorBuyOfferAfterT0();

/// Error raised when attempting to call claim on a Buy Offer after the t1 timestamp
error ErrorBuyOfferAfterT1();

/// Error raised when attempting to call refund on a Buy Offer in the ready state on or before the t1 timestamp
error ErrorBuyOfferNotAfterT1();

/// Error raised when attempting to call claimDeposit before t1 if the offer was not refunded
error ErrorBuyOfferNotAfterT1OrRefunded();

/// Error raised when attempting to call refund on a Buy Offer when the current timestamp is > t0 and <= t1
error ErrorBuyOfferBetweenT0AndT1();

/// Error raised when attempting to call claim on a Buy Offer when the current timestamp is not > t0 and <= t1
error ErrorBuyOfferNotBetweenT0AndT1();

/// Error raised when the address calling claim is not the taker of the offer
error ErrorBuyOfferNotTaker();

/// Error raised when attempting to call claim on an offer which is not in a state from which it can be claimed (TAKEN or READY)
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForClaim(OfferState state);

/// Error raised when attempting to call claimDeposit on a buy offer not in the READY or TAKEN state
error ErrorBuyOfferInvalidStateForClaimDeposit();

/// Error raised when attempting to call refund on an offer which is not in a state compatible with a refund call (TAKEN or READY)
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForRefund(OfferState state);

/// Error raised when calling claim with a private spend key whose associated public spend key is not that specified when taking the offer
error ErrorBuyOfferInvalidXMRPrivateSpendKey();

/// Error raised when calling refund with a private spend key whose associated public spend key is not that specified when creating the offer
error ErrorBuyOfferInvalidEVMPrivateSpendKey();

/// Error raised when calling refund with a private view key whose associated public veiew key is not that specified when creating the offer
error ErrorBuyOfferInvalidEVMPrivateViewKey();

/// Error raised when attempting to cancel a buy offer which is not in the OPEN state
/// @param state the current state of the offer
error ErrorBuyOfferInvalidStateForCancel(OfferState state);

/// Error raised when attempting to take a buy offer while an unused fundind request exists for the caller
error ErrorBuyOfferAvailableFundingRequest();

/// Error raised when deposit could not be sent back to the caller during a cancel or refund call
error ErrorBuyOfferUnableToRefund();

/// Error raised when taking a buy offer would lead to a price over the maximum specified for the offer
/// @param price the price at which the offer would be taken
/// @param maxprice the maximum price specified in the offer
error ErrorBuyOfferPriceTooHigh(uint256 price, uint256 maxprice);

/// Error raised when attempting to reduce an offer's maxamount value while transfering value in the tx
error ErrorBuyOfferNoValueAllowedWhenReducingMaxamount();

/// Error raised when creating or updating a buy offer with a dynamic price without providing a maxprice value
error ErrorBuyOfferMandatoryMaxpriceWithOraclePrice();

/// This error occurs when attempting to create a buy offer when the offer book is already at the configured limit
/// @param size the configured offer book maximum size
error ErrorBuyOfferMaximumOfferBookSizeReached(uint256 size);

/// This error is raised when price is 0 and oracleRatio is also 0
error ErrorBuyOfferNoPriceDefined();

/// This error is raised when a taker attempts to take a BuyOffer without sending any value with the transaction and
/// there is no FundingRequest for the taker's address.
error ErrorBuyOfferNoFundingRequestFound();

/// Error raised when the account taking the offer is not the specified counterparty
error ErrorBuyOfferInvalidCounterparty();

/// Error raised when there was an error sending back to the buyer the difference between the settlement amount and its deposit
error ErrorBuyOfferUnableToPayBuyer();

/// Error raised when attempting to call claimDeposit on a buy offer whose taker was funded
error ErrorBuyOfferCannotClaimDepositOfFundedOffer();

/// Error raised when providing a public key that has already been used as the message key of a buy offer
error ErrorBuyOfferUsedMessageKey();

/// Error raised when attempting to create a funding request for an amount which is 0
error ErrorFundingRequestZero();

/// Error raised when attempting to create a funding request from an address whose balance is above the configured threshold FUNDING_REQUEST_MAXBALANCE
/// The rationale is that the account should use its balance first.
/// @param balance the current balance of the requesting account
/// @param maxbalance the configured FUNDING_REQUEST_MAXBALANCE parameter
error ErrorFundingRequestBalanceTooHigh(uint256 balance, uint256 maxbalance);

/// Error raised when requesting a funding request from an account for which such a request already exists
error ErrorFundingRequestAlreadyExistsForAddress();

/// Error when attempting to fund a FundingRequest (via a call to fundFundingRequest) which has already been funded
error ErrorFundingRequestAlreadyFunded();

/// Error raised when attempting to fund a FundingRequest but with a transaction value which differs from
/// the amount specified in the FundingRequest.
/// @param amount The amount provided in the transaction.
/// @param expected The amount requested in the FundingRequest
error ErrorFundingRequestIncorrectAmount(uint256 amount, uint256 expected);

/// Error raised when attempting to defund a FundingRequest that is currently being used as part of a transaction.
error ErrorFundingRequestInUse();

/// Error raised when attempting to defund a FundingRequest from an address other than that of the funder.
error ErrorFundingRequestDefundableOnlyByFunder();

/// Error raised when attempting to defund a FundingRequest that has already been funded.
error ErrorFundingRequestCurrentlyFunded();

/// Error raised when attempting to claim a FundingRequest from an address other than that of the funder or the fundee
error ErrorFundingRequestClaimableOnlyByFunderOrFundee();

/// Error raised when attempting to claim a FundingRequest which is not in use
error ErrorFundingRequestNotInUse();

/// Error raised when referencing a non existent FundingRequest,
error ErrorFundingRequestNotFound();

/// Error raised when attempting to use a FundingRequest which has already been used.
error ErrorFundingRequestAlreadyInUse();

/// Error raised when attempting to use a FundingRequest which has not been funded.
error ErrorFundingRequestNotFunded();

/// Error raised when attempting to claim a FundingRequest which is not in a compatible state
error ErrorFundingRequestNotClaimable();

/// Error raised when the account requesting a FundingRequest is not an EOA.
/// Note that this may need to be adapted to account for EIP-7702
error ErrorFundingRequestNotAnEOA();

/// Error raised when a call to defundFundingRequest was unable to send the funds back to the funder
error ErrorFundingRequestUnableToRefund();

/// Error raised when attempting to create a FundingRequest with an amount which is lower than the promised fee
error ErrorFundingRequestAmountBelowFee();

/// Error raised when the fee is below the minimum configured fee ratio multiplied by the requested amount
error ErrorFundingRequestFeeBelowMinimumRatio(uint256 ratio);

/// Error raised when an account attempts to fund its own funding request
error ErrorFundingRequestCannotSelfFund();

/// This error occurs when attempting to create a sell offer when the offer book is already at the configured limit
/// @param size the configured maximum sell offer book size (AXIMUM_SELL_OFFER_BOOK_SIZE)
error ErrorSellOfferMaximumOfferBookSizeReached(uint256 size);

/// Error raised when attempting to create a sell offer with no deposit when no funding request exists for the calling account
error ErrorSellOfferNoFundingRequest();

/// Error raised when attempting to create a sell offer with no deposit when the existing funding request of the calling account is not funded
error ErrorSellOfferFundingRequestNotFunded();

/// Error raised when attempting to create a sell offer with no deposit when the existing funding request of the calling account is already used
error ErrorSellOfferFundingRequestAlreadyInUse();

/// Error raised when attempting to create or update a sell offer with an amount below the configured minimum (MINIMUM_SELL_OFFER)
/// @param minimum the current configured minimum sell offer amount
error ErrorSellOfferAmountBelowMinimum(uint256 minimum);

/// Error raised when attempting to create or update a sell offer with an amount above the configured maximum (MAXIMUM_SELL_OFFER)
/// That error is also raised when attempting to take a sell offer with an amont above the offer's maximum
/// @param maximum the current configured maxmimum sell offer amount
error ErrorSellOfferAmountAboveMaximum(uint256 maximum);

/// Error raised when a price ratio was specified jointly with a fixed price during creation or update of a sell offer
error ErrorSellOfferNoPriceRatioWithFixedPrice();

/// Error raised when a price offset was specified jointly with a fixed price during creation or update of a sell offer
error ErrorSellOfferNoPriceOffsetWithFixedPrice();

/// Error raised when a dynamic price was specified during creation or update of a sell offer but not price feed oracle is defined
error ErrorSellOfferNoPriceOracleDefined();

/// Error raised when no fixed price was specified and the price ratio was 0
error ErrorSellOfferInvalidOraclePriceRatio();

/// Error raised when the account attempting to update a sell offer is neither its owner nor its manager
error ErrorSellOfferInvalidCallerForUpdate();

/// Error raised when attempting to update a sell offer which is not in the OPEN state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForUpdate(OfferState state);

/// Error raised when attempting to perform an operation only avaialble to the owner of a Sell Offer from an address which is not the owner
error ErrorSellOfferNotOwner();

/// Error raised when cancelSellOffer was called by an account which is not the funder of the request or if the
/// required delay (2 * (T0_DELAY + T1_DELAY) has not passed since the funding request was funded.
error ErrorSellOfferNotCancellableByCaller();

/// Error raised when attempting to refund a sell offer from an address which is not the counterparty which took the offer
error ErrorSellOfferNotCounterparty();

/// Error raised when attempting to update the deposit amount of a sell offer which was created using a funding request
error ErrorSellOfferImmutableDeposit();

/// Error raised when the specified offer id is not a sell offer
error ErrorSellOfferUnknown();

/// Error raised when creating or updating a sell offer without specifying a fixed or dynamic price (price is 0 and ratio is 0)
error ErrorSellOfferNoPriceDefined();

/// Error raised when the amount resulting from taking a sell offer is not sufficient to cover the fees promised
/// to the funder of the FundingRequest which was used to create the sell offer.
/// This can be raised during calls to createSellOffer, updateSellOffer and takeSellOffer
error ErrorSellOfferAmountTooLowToCoverFundingFee();

/// Error raised when creating a sell offer with a public spend key which has already been used.
/// This is a check to ensure private spend keys are not reused across offers as this could lead to stolen funds.
error ErrorSellOfferPublicSpendKeyAlreadyUsed();

/// Error raised when the price specified when the price resulting from taking a sell offer is above the specified maximum
/// @param price the resulting price
/// @param maxprice the upper price limit which was specified
error ErrorSellOfferPriceTooHigh(uint256 price, uint256 maxprice);

/// Error raised when the dynamic price is negative price during a sell offer price estimation
error ErrorSellOfferNegativeDynamicPrice();

/// Error raised when the price reported by the price feed oracle is older than the configured limit (MREVMMaxage)
error ErrorSellOfferOraclePriceTooOld();

/// Error raised when the resulting amount of XMR being sold is below the minimum specified by the buyer
/// @param amount resulting amount of XMR being sold
/// @param minimum cpecified minimum amount the buyer wants to acquire
error ErrorSellOfferXMRAmountTooLow(uint256 amount, uint256 minimum);

/// Error raised when the XMR amount the taker is willing to buy is below the minimum set by the maker
/// @param amount amount of XMR the taker is agreeing to buy
/// @param minimum the minimum amount of XMR the maker is willing to sell
error ErrorSellOfferXMRAmountBelowOfferMinimum(uint256 amount, uint256 minimum);

/// Error raised when attempting to take an offer which is not in the OPEN state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForTake(OfferState state);

/// Error raised when attempting to call ready on an offer which is not in the TAKEN state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForReady(OfferState state);

/// Error raised when attempting to call ready on an offer after the t0 timestamp
error ErrorSellOfferAfterT0();

/// Error raised when the account attempting the call ready on an offer is not its taker
error ErrorSellOfferNotTaker();

/// Error raised when attempting to claim an offer after the t1 timestamp
error ErrorSellOfferAfterT1();

/// Error raised when attempting to refund an offer on or before timestamp t1
error ErrorSellOfferNotAfterT1();

/// This error is also raised when attempting to call claimDeposit before t1 or if the offer is not refunded
error ErrorSellOfferNotAfterT1OrRefunded();

/// Error raised when attempting to claim an offer on or before t0 or after t1
error ErrorSellOfferNotBetweenT0AndT1();

/// Error raised when attempting to refund an offer after t0 and on or before t1
error ErrorSellOfferBetweenT0AndT1();

/// Error raised when attempting to cancel an offer which is not in the OPEN state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForCancel(OfferState state);

/// Error raised when attempting to claim an offer which is not in the TAKEN or READY state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForClaim(OfferState state);

/// Error raised when attempting to call claimDeposit on a sell offer not in the READY or TAKEN state
error ErrorSellOfferInvalidStateForClaimDeposit();

/// Error raised when attempting to refund an offer which is neither in the TAKEN nor READY state
/// @param state the current state of the offer
error ErrorSellOfferInvalidStateForRefund(OfferState state);

/// Error raised when attempting to claim an offer with a private spend key which is not associated with the public spend key specified at offer creation time
error ErrorSellOfferInvalidXMRPrivateSpendKey();

/// Error raised when attempting to refund an offer with a private spend key which is not associated with the public spend key specified when taking the offer
error ErrorSellOfferInvalidEVMPrivateSpendKey();

/// Error raised when attempting to refund an offer with a private view key which is not associated with the public view key specified when taking the offer
error ErrorSellOfferInvalidEVMPrivateViewKey();

/// Error raised when attempting to create a sell offer with a non 0 deposit while having a currently unused funding request
error ErrorSellOfferAvailableFundingRequest();

/// Error raised during cancel or refund calls when a deposit cannot be sent back
error ErrorSellOfferUnableToRefund();

/// Error raised when attempting to claim an offer which has already been claimed
error ErrorSellOfferAlreadyClaimed();

/// Error raised when attempting to refund an offer which has already been refunded
error ErrorSellOfferAlreadyRefunded();

/// Error raised when taking an offer with a deposit above the required one and when the delta couldn't be sent back to the taker
error ErrorSellOfferUnableToSendAmountDelta();

/// Raised when creating or updateing a sell offer using a price oracle with no minprice specified
error ErrorSellOfferMandatoryMinpriceWithOraclePrice();

/// Error raised when the account taking the offer is not the specified counterparty
error ErrorSellOfferInvalidCounterparty();

/// Error raised when there was an error sending back to the buyer the difference between the settlement amount and its deposit
error ErrorSellOfferUnableToPayBuyer();

/// Error raised when a call to refund is performed in the same block in which take was called.
/// This is a mechanism to avoid having EVM takers call take and immediately call refund which would
/// simply be a way of draining the offer book to annoy sellers.
error ErrorSellOfferCannotRefundInTakenBlock();

/// Error raised when attempting to call claimDeposit on a sell offer whose maker was funded
error ErrorSellOfferCannotClaimDepositOfFundedOffer();

/// Error raised when providing a public key that has already been used as the message key of a sell offer
error ErrorSellOfferUsedMessageKey();

/// Generic error raised when an offer is invalid (either non existent, or not associated with caller)
error ErrorInvalidOffer();

/// Generic error raised when an offer is not of an expected type, most likely because it doesn not exist and is therefore of type INVALID
error ErrorInvalidOfferType();

/// Error raised when the payment of the claimer was unsuccessful
error ErrorUnableToPayClaimer();

/// Error raised when an offer deposit could not be claimed
error ErrorUnableToClaimDeposit();

/// Error raised when the payment of the funder was unsuccessful during a call to claim
error ErrorUnableToRepayFunder();

/// Error raised when attempting to send a message associated with an offer which is missing some message keys
error ErrorMissingMessageKeys();

/// Error raised when attempting to perform an operation which is only available to the contract's owner from an account which is not that owner
error ErrorNotOwner();

/// This error is raised when attempting to set T0 or T1 delay to a value lower than MINIMUM_DELAY
/// @param delay the specified delay
/// @param minimum the configured minimum
error ErrorDelayTooShort(uint256 delay, uint256 minimum);

/// Error thrown when receiving value > 0 in either receive or fallback.
error ErrorUnableToAcceptPayment();

/// Error raised when reentrancy is detected
error ErrorReentrancy();
