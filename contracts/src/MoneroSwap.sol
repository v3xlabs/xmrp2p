// SPDX-License-Identifier: MIT
//
// Copyright (c) 2025-2026  hbs
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

pragma solidity ^0.8.34;

import {Ed25519} from "./Ed25519.sol";
import "./Errors.sol";
import "./Enums.sol";
import "./Structs.sol";

// See https://docs.soliditylang.org/en/develop/natspec-format.html

/// @title A MoneroSwap contract for performing Atomic swaps between the native currency of an EVM based blockchain and Monero
/// @author hbs
/// @notice Use this contract responsibly
contract MoneroSwap {
    /// Number of decimals used by the EVM native currency
    uint256 constant EVM_DECIMALS = 18;

    /// Denominator used for ratios. This means that ratios are expressed in units such that RATIO_DENOMINATOR units means 1.0
    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;

    /// Number of units (piconeros) per XMR
    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;

    /// Minimum T0 and T1 delays.
    /// Setting those delays too low can lead to funds being 'stolen' by giving the XMR side the possibility to
    /// call claim almost immediately if T0 is too low. After T0, a taken offer becomes claimable even if it was not
    /// put in the READY state by the EVM side. So in order to avoid this we constrain the T0 and T1 delays to be at least
    /// MINIMUM_DELAY seconds
    uint256 constant MINIMUM_DELAY = 24 * 3_600; // twenty-four hours

    /// Contract Parameters.
    /// Those parameters may be set by the constructor or via the setParameters / setSavingsXDAIParameters functions
    struct Parameters {
        /// Maximum balance for requesting funding. Any account with a balance over this limit will not be able to create a funding request.
        /// Set this to 1 to disable the possibility to create funding requests
        uint256 FUNDING_REQUEST_MAXBALANCE;
        /// Minimum fee expressed as a ratio of the requested amount. The actual ratio is this value divided by RATIO_DENOMINATOR
        uint256 FUNDING_REQUEST_MIN_FEE_RATIO;
        /// Minimum buy offer (in wei)
        uint256 MINIMUM_BUY_OFFER;
        /// Maximum buy offer (in wei)
        uint256 MAXIMUM_BUY_OFFER;
        /// Minimum sell offer (in wei)
        uint256 MINIMUM_SELL_OFFER;
        /// Maximum sell offer (in wei)
        uint256 MAXIMUM_SELL_OFFER;
        /// Maximum number of active buy offers
        uint256 MAXIMUM_BUY_OFFER_BOOK_SIZE;
        /// Maximum number of active sell offers
        uint256 MAXIMUM_SELL_OFFER_BOOK_SIZE;
        /// The sell offer coverage ratio. A sell offer with a deposit of X cannot be taken
        /// for more than X * RATIO_DENOMINATOR / SELL_OFFER_COVERAGE_RATIO
        uint256 SELL_OFFER_COVERAGE_RATIO;
        //
        // The atomic swap protocol relies on two milestones t0 and t1 which define what each party can do.
        //
        // t0 and t1 are set when an offer is taken.
        //
        // Before t0, the XMR side of the swap should send the XMR to the computed address of the swap.
        // Once the EVM side of the swap sees the XMR, the ready function can be called. The ready function cannot be called after t0.
        // After t0 the offer is considered in the READY state implicitely.
        // Before t0, the EVM side of the swap can call refund to cancel the swap.
        // Once the offer is in READY state or t0 has passed, and before t1, the XMR side of the swap can call claim.
        // Once t1 has passed, only 'refund' can be called.
        //

        /// Delay (in s) until t0 (starting when offer is taken).
        uint256 T0_DELAY;
        /// Delay (in s) between t0 and t1
        uint256 T1_DELAY;
    }

    //
    // Contract parameters
    //
    Parameters PARAMETERS;

    //
    // Non parameter state
    //

    ///
    /// Total liability of the contract (in wei). This includes deposits for Buy and Sell offers
    /// and funds funding FundingRequests.
    ///
    /// The total liability is used to compute how much of the optionally accrued interests (from sDAI deposits) can
    /// be withdrawn.
    uint256 private liability;

    /// Id of the next Offer to create. This is common to both Buy and Sell offers.
    uint256 private nextOfferId = 1;

    /// Mapping from buy offer id to buy offer
    mapping(uint256 => Offer) private buyOffers;

    /// List of active buy offer ids.
    uint256[] private buyOfferIds;

    /// Mapping from sell offer id to sell offer
    mapping(uint256 => Offer) private sellOffers;

    /// List of active sell offer ids
    uint256[] private sellOfferIds;

    /// Mapping of address to FundingRequest. An address can only have a single active FundingRequest.
    mapping(address => FundingRequest) private fundingRequests;

    /// List of active funding requests
    address[] private activeFundingRequesters;

    /// Mapping of used public keys. This is kept track of so
    /// a public key cannot be reused as a public spend key, otherwise, if an offer which used
    /// a key has been completed, the associated private key might have been
    /// revealed which would compromise the security.
    /// Entries for public view keys and public message keys are also added. This adds a cost to
    /// createSellOffer and takeBuyOffer functions as an Ed25519 scalarmult must be performed to
    /// generate the publicViewKey from the privateViewKey, but this is for security reasons.
    mapping(uint256 => bool) private usedPublicKeys;

    /// Owner of the MoneroSwap contract
    address private owner;

    /// Mutex for non re-entrancy
    bool internal _mutex = false;

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        require(!_mutex, ErrorReentrancy());
        _mutex = true;
    }

    function _nonReentrantAfter() internal {
        _mutex = false;
    }

    //
    // Events
    //

    /// Event emitted when a new offer is created or when an offer changes state, the event contains the offer id and the offer type
    /// and current offer state.
    event OfferEvent(
        /// Id of offer
        uint256 offerid,
        /// Type of offer. This is indexed so that we can filter by type.
        OfferType indexed type_,
        /// State of offer. This is indexed so that we can filter by state.
        OfferState indexed state
    );

    /// Event emitted when a new FundingRequest is created. Funders can monitor those events to trigger their participation.
    event FundingEvent(
        /// Address requesting funding
        address requester,
        /// Amount requested (in wei)
        uint256 amount,
        /// Fee the requester is agreeing to pay (in wei)
        uint256 fee
    );

    constructor(address ownerAddress) payable {
        require(address(0) != ownerAddress);
        // No value is accepted since it cannot be withdrawn
        require(0 == msg.value);
        owner = ownerAddress;
        PARAMETERS.T0_DELAY = 24 * 3600;
        PARAMETERS.T1_DELAY = 24 * 3600;
        PARAMETERS.MINIMUM_BUY_OFFER = 1_000_000_000 gwei; // 1 xDAI
        PARAMETERS.MAXIMUM_BUY_OFFER = 1_000_000_000_000 ether; // 1 trillion xDAI
        PARAMETERS.MINIMUM_SELL_OFFER = 1_000_000_000 gwei; // 1 xDAI
        PARAMETERS.MAXIMUM_SELL_OFFER = 1_000_000_000_000 ether; // 1 trillion xDAI
        PARAMETERS.MAXIMUM_SELL_OFFER_BOOK_SIZE = 1_000_000;
        PARAMETERS.MAXIMUM_BUY_OFFER_BOOK_SIZE = 1_000_000;
        PARAMETERS.SELL_OFFER_COVERAGE_RATIO = RATIO_DENOMINATOR;
        PARAMETERS.FUNDING_REQUEST_MIN_FEE_RATIO = 0;
    }

    /// Receive function
    receive() external payable {
        require(0 == msg.value, ErrorUnableToAcceptPayment());
    }

    /// Fallback function
    fallback() external payable {
        require(0 == msg.value, ErrorUnableToAcceptPayment());
    }

    //
    // Buy Offer related functions
    //
    // ################################################################################

    ///
    /// Create a new buy offer
    ///
    /// @param counterparty The address of a designated counterparty for the offer. Set to 0 to allow offer to be taken by any address.
    /// @param price The (fixed) price of the offer, in wei per XMR.
    /// @param minxmr The minimum amount of XMR the offer is willing to buy. The offer cannot be taken if it would lead to less than this minimum. Value is expressed in piconeros
    /// @param publicspendkey The Monero public spend key.
    /// @param publicviewkey The Monero public view key.
    ///
    function createBuyOffer(
        address counterparty,
        uint256 price,
        uint256 minxmr,
        uint256 publicspendkey,
        uint256 publicviewkey
    ) public payable {
        //
        // Check if maximum number of active offers is reached
        //

        require(
            0 == PARAMETERS.MAXIMUM_BUY_OFFER_BOOK_SIZE ||
                buyOfferIds.length < PARAMETERS.MAXIMUM_BUY_OFFER_BOOK_SIZE,
            ErrorBuyOfferMaximumOfferBookSizeReached(buyOfferIds.length)
        );

        //
        // Check if the Monero public spend key has been used. First add the public view key.
        //

        usedPublicKeys[publicviewkey] = true;

        require(
            !usedPublicKeys[publicspendkey],
            ErrorBuyOfferPublicSpendKeyAlreadyUsed()
        );
        usedPublicKeys[publicspendkey] = true;

        //
        // EOA with a current FundingRequest cannot create BuyOffers
        //

        require(
            msg.sender != fundingRequests[msg.sender].requester,
            ErrorBuyOfferNoCreationWhenActiveFundingRequestExists()
        );

        //
        // Sent amount MUST be >= MINIMUM_BUY_OFFER
        //

        require(
            msg.value >= PARAMETERS.MINIMUM_BUY_OFFER,
            ErrorBuyOfferAmountBelowMinimum(PARAMETERS.MINIMUM_BUY_OFFER)
        );
        require(
            msg.value <= PARAMETERS.MAXIMUM_BUY_OFFER,
            ErrorBuyOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_BUY_OFFER)
        );

        // Price must be specified (no oracle fallback)
        require(0 != price, ErrorBuyOfferNoPriceDefined());

        Offer memory offer;

        offer.type_ = OfferType.BUY;
        offer.id = nextOfferId++;
        offer.state = OfferState.OPEN;
        offer.lastupdate = block.timestamp;
        offer.owner = msg.sender;
        offer.counterparty = counterparty;
        offer.manager = msg.sender;
        offer.maxamount = msg.value;
        offer.deposit = msg.value;
        offer.price = price;
        offer.minxmr = minxmr;
        offer.evmPublicSpendKey = publicspendkey;
        offer.evmPublicViewKey = publicviewkey;

        buyOffers[offer.id] = offer;
        buyOfferIds.push(offer.id);

        // Need to update the index by referencing buyOffers, because offer != buyOffers[offer.id] now
        buyOffers[offer.id].index = buyOfferIds.length - 1;

        //
        // Update the liability
        //
        liability += msg.value;

        //
        // Emit an OfferEvent
        //

        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Update an existing buy offer. Only the owner can update the offer.
    /// @param id the id of the offer to update
    /// @param counterparty address of explicit counterparty. Use 0x0 to allow any account to take the offer
    /// @param maxamount maximum amount to spend for buying Monero. This is used to reduce the maximum amount, in which case part of the deposit will be sent back
    /// @param price fixed price at which the buyer is willing to buy Monero (in wei per Monero)
    /// @param minxmr the minimum amount of XMR the buyer is willing to buy. The offer cannot be taken if it would lead to less than this minimum. Value is expressed in piconeros
    function updateBuyOffer(
        uint256 id,
        address counterparty,
        uint256 maxamount,
        uint256 price,
        uint256 minxmr
    ) public payable nonReentrant {
        Offer storage offer = buyOffers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(
            msg.sender == offer.owner,
            ErrorBuyOfferInvalidCallerForUpdate()
        );

        require(
            OfferState.OPEN == offer.state,
            ErrorBuyOfferInvalidStateForUpdate(offer.state)
        );

        if (maxamount < offer.maxamount) {
            // When reducing the max amount, msg.value MUST be 0
            require(
                msg.value == 0,
                ErrorBuyOfferNoValueAllowedWhenReducingMaxamount()
            );

            //
            // The offer cannot be reduced and fall outside the bounds
            //
            require(
                maxamount >= PARAMETERS.MINIMUM_BUY_OFFER,
                ErrorBuyOfferAmountBelowMinimum(PARAMETERS.MINIMUM_BUY_OFFER)
            );
            require(
                maxamount <= PARAMETERS.MAXIMUM_BUY_OFFER,
                ErrorBuyOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_BUY_OFFER)
            );

            // Adjust the maxmount and send the delta back to the owner
            uint256 delta = offer.maxamount - maxamount;
            offer.maxamount = maxamount;
            offer.state = OfferState.UPDATING;

            liability -= delta;
            offer.deposit = offer.maxamount;

            // Send back to the owner the delta amount
            (bool success, ) = payable(offer.owner).call{value: delta}("");
            offer.state = OfferState.OPEN;
            if (!success) {
                revert ErrorBuyOfferUnableToSendAmountDelta();
            }
        }

        if (0 != minxmr) {
            offer.minxmr = minxmr;
        }

        if (0 != price) {
            offer.price = price;
        }

        //
        // If value was sent with the call, update maxamount and deposit
        //

        if (msg.value > 0) {
            offer.maxamount += msg.value;

            // Check that we are still within the allowed range
            require(
                offer.maxamount >= PARAMETERS.MINIMUM_BUY_OFFER,
                ErrorBuyOfferAmountBelowMinimum(PARAMETERS.MINIMUM_BUY_OFFER)
            );
            require(
                offer.maxamount <= PARAMETERS.MAXIMUM_BUY_OFFER,
                ErrorBuyOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_BUY_OFFER)
            );

            offer.deposit += msg.value;
            liability += msg.value;
        }

        offer.counterparty = counterparty;

        offer.lastupdate = block.timestamp;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Retrieve a BuyOffer by id
    /// @param id id of the offer to retrieve
    function getBuyOffer(uint256 id) public view returns (Offer memory) {
        require(
            OfferState.INVALID != buyOffers[id].state,
            ErrorBuyOfferUnknown()
        );
        return buyOffers[id];
    }

    /// Take a buy offer. This is called by someone providing Monero. It will determine the offer counterparty and will set timestamps t0 and t1.
    ///
    /// @param id The id of the buy offer to take
    /// @param maxxmr Maximum amount of picoxmr the taker agrees to provide
    /// @param minprice Minimum price (in wei) of 1 XMR
    /// @param publicspendkey Monero Public spend key
    /// @param privateviewkey Monero Private view key
    ///
    function takeBuyOffer(
        uint256 id,
        uint256 maxxmr,
        uint256 minprice,
        uint256 publicspendkey,
        uint256 privateviewkey
    ) public payable nonReentrant {
        // Ensure the buy offer exists and is not yet taken
        Offer storage offer = buyOffers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(
            OfferState.OPEN == offer.state,
            ErrorBuyOfferInvalidStateForTake(offer.state)
        );

        require(
            address(0) == offer.counterparty ||
                offer.counterparty == msg.sender,
            ErrorBuyOfferInvalidCounterparty()
        );

        // If no deposit was sent (msg.value is 0), check for a valid funded FundingRequest
        uint amount = msg.value;
        uint256 fundingFee = 0;

        FundingRequest storage freq = fundingRequests[msg.sender];

        if (0 == amount) {
            // A FundingRequest must exist for that taker
            require(
                freq.requester == msg.sender,
                ErrorBuyOfferNoFundingRequestFound()
            );
            // The FundingRequest must be funded
            require(address(0) != freq.funder, ErrorFundingRequestNotFunded());
            // The FundingRequest must not be used yet
            require(0 == freq.usedby, ErrorFundingRequestAlreadyInUse());

            freq.usedby = id;
            amount = freq.amount;
            fundingFee = freq.fee;
            offer.funded = true;
            offer.takerDeposit = 0;
        } else {
            // Non 0 value can only be specified if the taker has no unused active FundingRequest
            if (msg.sender == freq.requester) {
                require(
                    0 != freq.usedby,
                    ErrorBuyOfferAvailableFundingRequest()
                );
            }
            offer.takerDeposit = msg.value;
        }

        // Ensure that the taker can provide the minimum amount of XMR the maker requested
        require(
            maxxmr >= offer.minxmr,
            ErrorBuyOfferXMRAmountTooLow(maxxmr, offer.minxmr)
        );

        // Compute the public view key associated with the provided private view key and add it
        // to the usedPublicKeys mapping. This is a costly operation but it adds security.

        (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateviewkey);
        uint256 publicviewkey = Ed25519.changeEndianness(
            Ed25519.compressPoint(x, y)
        );
        usedPublicKeys[publicviewkey] = true;

        // Ensure the provided public key has not yet been used
        require(
            !usedPublicKeys[publicspendkey],
            ErrorBuyOfferPublicSpendKeyAlreadyUsed()
        );
        usedPublicKeys[publicspendkey] = true;

        // Verify the offer's fixed price meets the taker's minimum
        require(
            offer.price >= minprice,
            ErrorBuyOfferPriceTooLow(offer.price, minprice)
        );
        uint256 price = offer.price;

        // Compute the maximum transaction amount (in wei) given the deposit/funding and the coverage ratio
        amount =
            (amount * RATIO_DENOMINATOR) /
            PARAMETERS.SELL_OFFER_COVERAGE_RATIO;

        // Cap amount to the maker's deposit
        if (amount > offer.maxamount) {
            amount = offer.maxamount;
        }

        // Compute the maximum amount of XMR (in picoxmr) that the taker can sell given the price and the deposit/funding
        uint256 picoxmramount = (UNITS_PER_XMR * amount) / price;

        if (picoxmramount > maxxmr) {
            picoxmramount = maxxmr;
        }

        require(
            picoxmramount >= offer.minxmr,
            ErrorBuyOfferXMRAmountTooLow(picoxmramount, offer.minxmr)
        );

        // Ensure that the amount covers at least the funding fee
        if (fundingFee > 0) {
            require(
                (picoxmramount * price) / UNITS_PER_XMR >= fundingFee,
                ErrorBuyOfferAmountTooLowToCoverFundingFee()
            );
        }

        offer.counterparty = msg.sender;
        offer.blockTaken = block.number;
        offer.xmrPublicSpendKey = publicspendkey;
        offer.xmrPrivateViewKey = privateviewkey;
        offer.finalprice = price;
        offer.finalxmr = picoxmramount;
        offer.state = OfferState.TAKEN;
        offer.lastupdate = block.timestamp;

        // Set milestones
        offer.t0 = block.timestamp + PARAMETERS.T0_DELAY;
        offer.t1 = offer.t0 + PARAMETERS.T1_DELAY;

        // liability only increases by the actual deposit. If the taker is funded by a FundingRequest, liability has already been updated
        liability += msg.value;

        //
        // If the settlement amount is less than the maker's deposit, return the delta to the maker
        // immediately so in case its EOA cannot accept payments the call to takeBuyOffer fails.
        //

        uint256 settlement = (offer.finalprice * offer.finalxmr) /
            UNITS_PER_XMR;

        if (settlement < offer.deposit) {
            uint256 delta = offer.deposit - settlement;
            // update liability
            liability -= delta;
            // update offer deposit
            offer.deposit -= delta;
            // pay the delta to the maker
            (bool res, ) = payable(offer.owner).call{value: delta}("");
            require(res, ErrorBuyOfferUnableToPayBuyer());
        }

        //
        // Emit an offer event
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Return a slice of buy offers. Note that given the way the offers are managed by the contract,
    /// pagination may return duplicate results or miss results when offers were refunded/cancelled/claimed between the calls to listBuyOffers
    /// @param offset offset in the list of the first offer to return
    /// @param count maximum number of offers to return
    function listBuyOffers(
        uint offset,
        uint count
    ) public view returns (Offer[] memory) {
        // If the offset is past the end of the array, set count to 0
        if (offset >= buyOfferIds.length) {
            count = 0;
        } else {
            uint256 c = buyOfferIds.length - offset;
            if (c < count) {
                count = c;
            }
        }

        Offer[] memory result = new Offer[](count);

        for (uint i = offset; i < offset + count; i++) {
            result[i - offset] = buyOffers[buyOfferIds[i]];
        }

        return result;
    }

    /// Cancel a buy offer.
    /// @param id id of the offer to cancel
    function cancelBuyOffer(uint256 id) public nonReentrant {
        Offer storage offer = buyOffers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(offer.owner == msg.sender, ErrorBuyOfferNotOwner());
        require(
            OfferState.OPEN == offer.state,
            ErrorBuyOfferInvalidStateForCancel(offer.state)
        );

        uint256 lastOfferId = buyOfferIds[buyOfferIds.length - 1];
        Offer storage lastOffer = buyOffers[lastOfferId];
        buyOfferIds[offer.index] = lastOffer.id;
        lastOffer.index = offer.index;
        buyOfferIds.pop();

        // Refund the offer owner
        liability -= offer.deposit;
        offer.state = OfferState.CANCELLED;
        offer.lastupdate = block.timestamp;
        (bool res, ) = payable(offer.owner).call{value: offer.deposit}("");
        require(res, ErrorBuyOfferUnableToRefund());

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    //
    // SellOffer related functions
    //
    // ################################################################################

    /// Create a sell offer.
    /// @param counterparty address of an explicit counterparty. Use 0x0 to allow any account to take the offer
    /// @param price fixed price, in wei per XMR
    /// @param minxmr minimum amount of XMR (in piconeros) the seller is willing to sell
    /// @param maxxmr maximum amount of XMR (in piconeros) the seller can provide.
    /// @param publicspendkey Monero public spend key
    /// @param privateviewkey Monero private view key
    function createSellOffer(
        address counterparty,
        uint256 price,
        uint256 minxmr,
        uint256 maxxmr,
        uint256 publicspendkey,
        uint256 privateviewkey
    ) public payable {
        //
        // Check if maximum number of active offers is reached
        //

        require(
            0 == PARAMETERS.MAXIMUM_SELL_OFFER_BOOK_SIZE ||
                sellOfferIds.length < PARAMETERS.MAXIMUM_SELL_OFFER_BOOK_SIZE,
            ErrorSellOfferMaximumOfferBookSizeReached(sellOfferIds.length)
        );

        //
        // Check if the pubkey has been used. Add the public view key
        //

        (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateviewkey);
        uint256 publicviewkey = Ed25519.changeEndianness(
            Ed25519.compressPoint(x, y)
        );
        usedPublicKeys[publicviewkey] = true;
        require(
            !usedPublicKeys[publicspendkey],
            ErrorSellOfferPublicSpendKeyAlreadyUsed()
        );
        usedPublicKeys[publicspendkey] = true;

        //
        // If no amount was sent, check if there is a funded FundingRequest for the sender
        //

        uint256 amount;

        Offer memory offer;
        offer.id = nextOfferId++;

        FundingRequest storage freq = fundingRequests[msg.sender];

        if (0 == msg.value) {
            // Offer creator must have a current FundingRequest
            require(
                msg.sender == freq.requester,
                ErrorSellOfferNoFundingRequest()
            );
            // The FundingRequest must be funded
            require(
                address(0) != freq.funder,
                ErrorSellOfferFundingRequestNotFunded()
            );
            // The FundingRequest must not be used yet
            require(
                0 == freq.usedby,
                ErrorSellOfferFundingRequestAlreadyInUse()
            );

            amount = freq.amount;
            freq.usedby = offer.id;
            offer.funded = true;
        } else {
            // A value can be non 0 only if the sender has no non used FundingRequest
            if (msg.sender == freq.requester) {
                require(
                    0 != freq.usedby,
                    ErrorSellOfferAvailableFundingRequest()
                );
            }
            amount = msg.value;
            offer.deposit = msg.value;
            liability += msg.value;
        }

        //
        // Adjust the maxamount based on the coverage ratio
        //

        amount =
            (amount * RATIO_DENOMINATOR) /
            PARAMETERS.SELL_OFFER_COVERAGE_RATIO;

        //
        // Sent amount MUST be >= MINIMUM_SELL_OFFER
        //

        require(
            amount >= PARAMETERS.MINIMUM_SELL_OFFER,
            ErrorSellOfferAmountBelowMinimum(PARAMETERS.MINIMUM_SELL_OFFER)
        );
        require(
            amount <= PARAMETERS.MAXIMUM_SELL_OFFER,
            ErrorSellOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_SELL_OFFER)
        );

        // Price must be specified
        require(0 != price, ErrorSellOfferNoPriceDefined());

        // If the offer is funded by a FundingRequest ensure that the minimum settlement amount covers the fee
        if (offer.funded) {
            require(
                (price * minxmr) / UNITS_PER_XMR >= freq.fee,
                ErrorSellOfferAmountTooLowToCoverFundingFee()
            );
        }

        offer.type_ = OfferType.SELL;

        offer.state = OfferState.OPEN;
        offer.owner = msg.sender;
        offer.counterparty = counterparty;
        offer.lastupdate = block.timestamp;
        offer.manager = msg.sender;
        offer.maxamount = amount;
        offer.price = price;
        offer.minxmr = minxmr;
        offer.maxxmr = maxxmr;
        offer.xmrPublicSpendKey = publicspendkey;
        offer.xmrPrivateViewKey = privateviewkey;

        sellOffers[offer.id] = offer;
        sellOfferIds.push(offer.id);

        // Need to reference sellOffers because sellOffers[offer.id] != offer now.
        sellOffers[offer.id].index = sellOfferIds.length - 1;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Update a sell offer
    /// @param id id of the offer to update
    /// @param counterparty address of an explicit counterparty, or 0x0 to allow any account to take the offer
    /// @param price Fixed price at which the XMR will be sold
    /// @param minxmr Minimum amount of XMR (in piconeros) the owner is willing to sell
    /// @param maxxmr Maximum amount of XMR (in piconeros) the owner is willing to sell
    function updateSellOffer(
        uint256 id,
        address counterparty,
        uint256 price,
        uint256 minxmr,
        uint256 maxxmr
    ) public payable {
        Offer storage offer = sellOffers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());

        require(
            OfferState.OPEN == offer.state,
            ErrorSellOfferInvalidStateForUpdate(offer.state)
        );

        require(
            msg.sender == offer.owner,
            ErrorSellOfferInvalidCallerForUpdate()
        );

        // Offers which were funded by a FundingRequest cannot change their deposit
        FundingRequest storage freq = fundingRequests[offer.owner];
        if (offer.funded && offer.id == freq.usedby) {
            require(0 == msg.value, ErrorSellOfferImmutableDeposit());
        } else if (0 != msg.value) {
            // Adjust the deposit and maximum amount if value is non 0
            offer.deposit += msg.value;
            offer.maxamount =
                (offer.deposit * RATIO_DENOMINATOR) /
                PARAMETERS.SELL_OFFER_COVERAGE_RATIO;

            require(
                offer.maxamount <= PARAMETERS.MAXIMUM_SELL_OFFER,
                ErrorSellOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_SELL_OFFER)
            );
            require(
                offer.maxamount >= PARAMETERS.MINIMUM_SELL_OFFER,
                ErrorSellOfferAmountBelowMinimum(PARAMETERS.MINIMUM_SELL_OFFER)
            );

            liability += msg.value;
        }

        if (0 != price) {
            offer.price = price;
        }

        if (0 != minxmr) {
            offer.minxmr = minxmr;
        }

        if (0 != maxxmr) {
            offer.maxxmr = maxxmr;
        }

        offer.counterparty = counterparty;

        offer.lastupdate = block.timestamp;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Retrieve a Sell Offer by id
    /// @param id id of the offer to retrieve
    function getSellOffer(uint256 id) public view returns (Offer memory) {
        require(
            OfferState.INVALID != sellOffers[id].state,
            ErrorSellOfferUnknown()
        );
        return sellOffers[id];
    }

    ///
    /// Take a sell offer. This will determine the counterparty and will set the timestamps t0 and t1.
    ///
    /// @param id id of the offer to take
    /// @param minxmr The minimum amount of piconeros that the taker wishes to acquire
    /// @param maxprice The maximum price per XMR (in wei) that the taker is willing to pay
    /// @param publicspendkey Monero public spend key generated by the taker
    /// @param publicviewkey Monero public view key generated by the taker
    function takeSellOffer(
        uint256 id,
        uint256 minxmr,
        uint256 maxprice,
        uint256 publicspendkey,
        uint256 publicviewkey
    ) public payable nonReentrant {
        // Ensure the sell offer exists and is not yet taken
        Offer storage offer = sellOffers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());

        require(
            OfferState.OPEN == offer.state,
            ErrorSellOfferInvalidStateForTake(offer.state)
        );

        require(
            address(0) == offer.counterparty ||
                offer.counterparty == msg.sender,
            ErrorSellOfferInvalidCounterparty()
        );

        // Ensure the provided public key has not yet been used
        usedPublicKeys[publicviewkey] = true;
        require(
            !usedPublicKeys[publicspendkey],
            ErrorSellOfferPublicSpendKeyAlreadyUsed()
        );
        usedPublicKeys[publicspendkey] = true;

        // Verify the offer's fixed price meets the taker's maximum
        require(
            offer.price <= maxprice,
            ErrorSellOfferPriceTooHigh(offer.price, maxprice)
        );
        uint256 price = offer.price;

        // Compute the amount of picoxmr the taker can buy (limited by the offer's maxamount)
        uint256 picoxmr = ((
            (msg.value > offer.maxamount) ? offer.maxamount : msg.value
        ) * UNITS_PER_XMR) / price;

        // Limit the buyable amount to the maximum provided by the offer
        if (picoxmr > offer.maxxmr) {
            picoxmr = offer.maxxmr;
        }

        // Ensure that the taker can buy the the minimum amount of XMR the maker requested
        require(
            picoxmr >= offer.minxmr,
            ErrorSellOfferXMRAmountBelowOfferMinimum(picoxmr, offer.minxmr)
        );

        // Ensure that the transaction would buy at least the amount of XMR requested by the taker
        require(
            picoxmr >= minxmr,
            ErrorSellOfferXMRAmountTooLow(picoxmr, minxmr)
        );

        // Compute the amount to be spent by the taker
        uint256 amount = (picoxmr * price) / UNITS_PER_XMR;

        // Amount must be <= maxamount, otherwise a deposit lower than the required ratio could be used by the seller
        // Given the way picoxmr is computed, this should always be true
        require(
            amount <= offer.maxamount,
            ErrorSellOfferAmountAboveMaximum(offer.maxamount)
        );

        // This is here for safety, but given the way picoxmr is computed it should never happen except maybe due to rounding errors
        require(
            amount <= msg.value,
            ErrorSellOfferAmountAboveMaximum(msg.value)
        );

        /// If the offer was funded, ensure the settlement amount is enough to cover the funding fee
        if (offer.funded) {
            FundingRequest storage freq = fundingRequests[offer.owner];
            require(
                amount >= freq.fee,
                ErrorSellOfferAmountTooLowToCoverFundingFee()
            );
        }

        offer.counterparty = msg.sender;
        offer.blockTaken = block.number;

        offer.evmPublicSpendKey = publicspendkey;
        offer.evmPublicViewKey = publicviewkey;
        offer.finalprice = price;
        offer.finalxmr = picoxmr;
        offer.state = OfferState.TAKEN;
        offer.lastupdate = block.timestamp;

        // Set milestones
        offer.t0 = block.timestamp + PARAMETERS.T0_DELAY;
        offer.t1 = offer.t0 + PARAMETERS.T1_DELAY;

        offer.takerDeposit = amount;
        liability += amount;

        // Send back the delta between msg.value and amount
        if (msg.value > amount) {
            (bool res, ) = payable(msg.sender).call{value: msg.value - amount}(
                ""
            );
            require(res, ErrorSellOfferUnableToSendAmountDelta());
        }

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Return a slice of sell offers
    /// As for listBuyOffers, depending on created/claimed/refunded offers, pagination may miss some offers or return duplicates across calls
    /// @param offset offset of the first offer to return
    /// @param count number of offers to return
    function listSellOffers(
        uint offset,
        uint count
    ) public view returns (Offer[] memory) {
        // If the offset is past the end of the array, set count to 0
        if (offset >= sellOfferIds.length) {
            count = 0;
        } else {
            uint256 c = sellOfferIds.length - offset;
            if (c < count) {
                count = c;
            }
        }

        Offer[] memory result = new Offer[](count);

        for (uint i = offset; i < offset + count; i++) {
            result[i - offset] = sellOffers[sellOfferIds[i]];
        }

        return result;
    }

    /// Cancel a sell offer.
    /// A sell offer can be cancelled by its owner but in the case it was funded by a third party it can
    /// also be cancelled by the funder after a delay so the funder is not at risk of not being able to
    /// recover its funds due to a stale OPEN offer which is never taken.
    /// @param id id of the offer to cancel
    function cancelSellOffer(uint256 id) public nonReentrant {
        Offer storage offer = sellOffers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());
        require(
            OfferState.OPEN == offer.state,
            ErrorSellOfferInvalidStateForCancel(offer.state)
        );

        FundingRequest storage freq = fundingRequests[offer.owner];

        if (offer.owner != msg.sender) {
            require(
                offer.funded &&
                    offer.id == freq.usedby &&
                    msg.sender == freq.funder &&
                    block.timestamp >
                    freq.fundedOn +
                        2 *
                        (PARAMETERS.T0_DELAY + PARAMETERS.T1_DELAY),
                ErrorSellOfferNotCancellableByCaller()
            );
        }

        offer.state = OfferState.CANCELLED;
        offer.lastupdate = block.timestamp;

        uint256 lastOfferId = sellOfferIds[sellOfferIds.length - 1];
        Offer storage lastOffer = sellOffers[lastOfferId];
        sellOfferIds[offer.index] = lastOffer.id;
        lastOffer.index = offer.index;
        sellOfferIds.pop();

        // Refund the offer owner or unuse the funding request
        if (offer.funded && offer.id == freq.usedby) {
            // Offer was funded, unuse the FundingRequest
            freq.usedby = 0;
        } else {
            // No FundingRequest, deposit should go back to the owner
            liability -= offer.deposit;

            (bool res, ) = payable(offer.owner).call{value: offer.deposit}("");
            require(res, ErrorSellOfferUnableToRefund());
        }

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    //
    // Settlement related functions
    //
    // ##############################################################

    /// The ready function is called by the XMR buyer once it has validated that the XMR were deposited on the target address.
    /// The ready function can be called until offer.t0
    /// @param id Offer id
    function ready(uint256 id) public {
        Offer storage offer = buyOffers[id];

        if (OfferType.INVALID == offer.type_) {
            offer = sellOffers[id];
        }

        if (OfferType.BUY == offer.type_) {
            require(
                OfferState.TAKEN == offer.state,
                ErrorBuyOfferInvalidStateForReady(offer.state)
            );
            require(msg.sender == offer.owner, ErrorBuyOfferNotOwner());
            require(block.timestamp <= offer.t0, ErrorBuyOfferAfterT0());
        } else if (OfferType.SELL == offer.type_) {
            require(
                OfferState.TAKEN == offer.state,
                ErrorSellOfferInvalidStateForReady(offer.state)
            );
            require(msg.sender == offer.counterparty, ErrorSellOfferNotTaker());
            require(block.timestamp <= offer.t0, ErrorSellOfferAfterT0());
        } else {
            revert ErrorInvalidOffer();
        }

        offer.state = OfferState.READY;
        offer.lastupdate = block.timestamp;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// The claim function is called by the XMR seller once the buyer has confirmed the offer by calling ready
    /// The claim function can be called after offer.t0 and until offer.t1 if the offer is in state TAKEN and
    /// before offer.t1 if it is in state READY
    /// @param id Offer id
    /// @param id privateSpendKey The XMR side of the offer privateSpendKey
    function claim(uint256 id, uint256 privateSpendKey) public nonReentrant {
        Offer storage offer = buyOffers[id];

        if (OfferType.INVALID == offer.type_) {
            offer = sellOffers[id];
        }

        //
        // claim can only be called when offer is in state TAKEN (after t0, before t1)
        // or in state READY (before t1)
        //

        FundingRequest storage freq;

        if (OfferType.BUY == offer.type_) {
            if (OfferState.TAKEN == offer.state) {
                require(
                    block.timestamp > offer.t0 && block.timestamp <= offer.t1,
                    ErrorBuyOfferNotBetweenT0AndT1()
                );
            } else if (OfferState.READY == offer.state) {
                require(block.timestamp <= offer.t1, ErrorBuyOfferAfterT1());
            } else {
                revert ErrorBuyOfferInvalidStateForClaim(offer.state);
            }
            require(msg.sender == offer.counterparty, ErrorBuyOfferNotTaker());
            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.xmrPublicSpendKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidXMRPrivateSpendKey()
            );
            offer.xmrPrivateSpendKey = privateSpendKey;
            freq = fundingRequests[offer.counterparty];
        } else if (OfferType.SELL == offer.type_) {
            if (OfferState.TAKEN == offer.state) {
                require(
                    block.timestamp > offer.t0 && block.timestamp <= offer.t1,
                    ErrorSellOfferNotBetweenT0AndT1()
                );
            } else if (OfferState.READY == offer.state) {
                require(block.timestamp <= offer.t1, ErrorSellOfferAfterT1());
            } else {
                revert ErrorSellOfferInvalidStateForClaim(offer.state);
            }
            require(msg.sender == offer.owner, ErrorSellOfferNotOwner());
            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.xmrPublicSpendKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorSellOfferInvalidXMRPrivateSpendKey()
            );
            offer.xmrPrivateSpendKey = privateSpendKey;
            freq = fundingRequests[offer.owner];
        } else {
            revert ErrorInvalidOffer();
        }

        offer.state = OfferState.CLAIMED;
        offer.lastupdate = block.timestamp;

        //
        // Handle funding request
        //

        uint256 settlement = (offer.finalprice * offer.finalxmr) /
            UNITS_PER_XMR;
        uint256 payToClaimer = settlement;

        if (offer.funded && freq.usedby == offer.id) {
            //
            // Delete FundingRequest
            //
            address lastfreq = activeFundingRequesters[
                activeFundingRequesters.length - 1
            ];
            activeFundingRequesters[freq.index] = lastfreq;
            fundingRequests[lastfreq].index = freq.index;
            activeFundingRequesters.pop();

            //
            // Pay the funder + fee
            //

            uint256 payToFunder = freq.amount + freq.fee;
            payToClaimer -= freq.fee;
            liability -= payToFunder;

            // Delete FundingRequest if payment was successful so claimFundingRequest doesn't do anything
            // DO NOT fail if payment fails, otherwise an EIP-7702 delegation on the funder would prevent
            // the seller from calling claim
            if (payToFunder > 0) {
                (bool fres, ) = payable(freq.funder).call{value: payToFunder}(
                    ""
                );
                if (fres) {
                    delete fundingRequests[msg.sender];
                } else {
                    // We need to update liability back with the amount and fee of the funding request
                    liability += payToFunder;
                }
            }
        } else {
            // Set takerDeposit/deposit to 0 so claimDeposit cannot pay twice

            // Offer was self funded
            if (OfferType.BUY == offer.type_) {
                if (offer.takerDeposit > 0) {
                    payToClaimer += offer.takerDeposit;
                    offer.takerDeposit = 0;
                }
            } else if (OfferType.SELL == offer.type_) {
                if (offer.deposit > 0) {
                    payToClaimer += offer.deposit;
                    offer.deposit = 0;
                }
            }
        }

        //
        // Pay the seller (selling price + possible deposit)
        //

        liability -= payToClaimer;

        if (payToClaimer > 0) {
            (bool res, ) = payable(msg.sender).call{value: payToClaimer}("");
            require(res, ErrorUnableToPayClaimer());
        }

        //
        // Remove offer from active lists
        //

        if (OfferType.BUY == offer.type_) {
            uint256 lastOfferId = buyOfferIds[buyOfferIds.length - 1];
            Offer storage lastOffer = buyOffers[lastOfferId];
            buyOfferIds[offer.index] = lastOffer.id;
            lastOffer.index = offer.index;
            buyOfferIds.pop();
        } else {
            uint256 lastOfferId = sellOfferIds[sellOfferIds.length - 1];
            Offer storage lastOffer = sellOffers[lastOfferId];
            sellOfferIds[offer.index] = lastOffer.id;
            lastOffer.index = offer.index;
            sellOfferIds.pop();
        }

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Refund an offer. This is called by the EVM side of an offer when the Monero side has not sent the correct amount of XMR
    /// to the offer specific address.
    /// The call to refund, if successful (if the provided private keys are indeed those associated with the offer's public keys), will refund
    /// the buyer's deposit and will either refund the seller's deposit or will unuse its funding request.
    /// Since the private keys of the EVM side are provided as part of the call, the Monero side can transfer any amount of XMR it has sent to the offer's address
    /// back to one of its address.
    /// This function can be called before t0 until ready is called and after t1 if the offer was not claimed.
    /// Note that if a FundingRequest was used, if will continue to exist but will be put back in state unused.
    /// @param id The id of the offer to refund
    /// @param privateSpendKey The private spend key of the offer owner
    /// @param privateViewKey The private view key of the offer owner
    function refund(
        uint256 id,
        uint256 privateSpendKey,
        uint256 privateViewKey
    ) public nonReentrant {
        Offer storage offer = buyOffers[id];

        if (OfferType.INVALID == offer.type_) {
            offer = sellOffers[id];
        }

        if (OfferType.BUY == offer.type_) {
            // If offer is in state TAKEN, then timestamp must either be <= t0 or > t1
            if (OfferState.TAKEN == offer.state) {
                require(
                    block.timestamp <= offer.t0 || block.timestamp > offer.t1,
                    ErrorBuyOfferBetweenT0AndT1()
                );
            } else if (OfferState.READY == offer.state) {
                // For READY state, timestamp must be > t1
                require(block.timestamp > offer.t1, ErrorBuyOfferNotAfterT1());
            } else {
                // refund can only be called for offers in the READY or TAKEN state
                revert ErrorBuyOfferInvalidStateForRefund(offer.state);
            }
            require(msg.sender == offer.owner, ErrorBuyOfferNotOwner());

            // Check private spend and view keys
            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.evmPublicSpendKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidEVMPrivateSpendKey()
            );
            (x, y) = Ed25519.scalarMultBase(privateViewKey);
            require(
                offer.evmPublicViewKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidEVMPrivateViewKey()
            );
        } else if (OfferType.SELL == offer.type_) {
            // If offer is in state TAKEN, then timestamp must either be <= t0 or > t1
            // Also a taken offer cannot be refunded in the same block in which it was taken
            if (OfferState.TAKEN == offer.state) {
                require(
                    block.number > offer.blockTaken,
                    ErrorSellOfferCannotRefundInTakenBlock()
                );
                require(
                    block.timestamp <= offer.t0 || block.timestamp > offer.t1,
                    ErrorSellOfferBetweenT0AndT1()
                );
            } else if (OfferState.READY == offer.state) {
                // For READY state, timestamp must be > t1
                require(block.timestamp > offer.t1, ErrorSellOfferNotAfterT1());
            } else {
                // refund can only be called for offers in the READY or TAKEN state
                revert ErrorSellOfferInvalidStateForRefund(offer.state);
            }

            require(
                msg.sender == offer.counterparty,
                ErrorSellOfferNotCounterparty()
            );

            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.evmPublicSpendKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorSellOfferInvalidEVMPrivateSpendKey()
            );
            (x, y) = Ed25519.scalarMultBase(privateViewKey);
            require(
                offer.evmPublicViewKey ==
                    Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorSellOfferInvalidEVMPrivateViewKey()
            );
        } else {
            revert ErrorInvalidOffer();
        }

        offer.evmPrivateSpendKey = privateSpendKey;
        offer.evmPrivateViewKey = privateViewKey;

        offer.state = OfferState.REFUNDED;
        offer.lastupdate = block.timestamp;

        //
        // Send back the amount
        //

        FundingRequest storage freq;

        if (OfferType.BUY == offer.type_) {
            liability -= offer.deposit;
            (bool res, ) = payable(msg.sender).call{value: offer.deposit}("");
            require(res, ErrorBuyOfferUnableToRefund());

            // Refund the taker's deposit
            if (offer.takerDeposit > 0) {
                uint256 takerDeposit = offer.takerDeposit;
                liability -= takerDeposit;
                offer.takerDeposit = 0;
                (res, ) = payable(offer.counterparty).call{value: takerDeposit}(
                    ""
                );
                if (!res) {
                    offer.takerDeposit = takerDeposit;
                    liability += takerDeposit;
                }
            } else {
                freq = fundingRequests[offer.counterparty];
                if (freq.usedby == offer.id) {
                    // Offer taking was financed by a funding request, clear its usedby field since it is no longer used
                    freq.usedby = 0;
                }
            }
        } else {
            liability -= offer.takerDeposit;
            (bool res, ) = payable(msg.sender).call{value: offer.takerDeposit}(
                ""
            );
            require(res, ErrorSellOfferUnableToRefund());

            // Refund the seller's deposit if the offer was not financed by a funding request
            freq = fundingRequests[offer.owner];

            if (freq.usedby == offer.id && freq.requester == offer.owner) {
                freq.usedby = 0;
            } else if (offer.deposit > 0) {
                uint256 deposit = offer.deposit;
                liability -= deposit;
                offer.deposit = 0;
                (res, ) = payable(offer.owner).call{value: deposit}("");
                if (!res) {
                    offer.deposit = deposit;
                    liability += deposit;
                }
            }
        }

        //
        // Remove offer from active lists
        //

        if (OfferType.BUY == offer.type_) {
            uint256 lastOfferId = buyOfferIds[buyOfferIds.length - 1];
            Offer storage lastOffer = buyOffers[lastOfferId];
            buyOfferIds[offer.index] = lastOffer.id;
            lastOffer.index = offer.index;
            buyOfferIds.pop();
        } else {
            uint256 lastOfferId = sellOfferIds[sellOfferIds.length - 1];
            Offer storage lastOffer = sellOffers[lastOfferId];
            sellOfferIds[offer.index] = lastOffer.id;
            lastOffer.index = offer.index;
            sellOfferIds.pop();
        }

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// This function allows the Monero side of a swap to claim its deposit. This is to
    /// allow the deposit to be recovered in the case the EVM side of the swap never calls
    /// refund after T1. XMR would be lost, EVM currency would be stuck in the contract but
    /// at least the deposit made by the XMR side would be recovered.
    /// Another case if when the EVM side calls refund but sending the deposit back to the XMR side failed.
    /// @param id id of the offer for which to claim the deposit
    function claimDeposit(uint256 id) public nonReentrant {
        Offer storage offer = buyOffers[id];

        if (OfferType.INVALID == offer.type_) {
            offer = sellOffers[id];
        }

        uint256 deposit = 0;

        // claimDeposit cannot be called on funded offers
        // claimDeposit can only be called after T1 and only if the offer is in the READY or TAKEN state
        // OR if the offer is in the REFUNDED state
        if (OfferType.BUY == offer.type_) {
            require(
                !offer.funded,
                ErrorBuyOfferCannotClaimDepositOfFundedOffer()
            );
            require(
                block.timestamp > offer.t1 ||
                    OfferState.REFUNDED == offer.state,
                ErrorBuyOfferNotAfterT1OrRefunded()
            );
            // This is tested for safety, it should never happen
            require(
                OfferState.READY == offer.state ||
                    OfferState.TAKEN == offer.state ||
                    OfferState.REFUNDED == offer.state,
                ErrorBuyOfferInvalidStateForClaimDeposit()
            );
            require(msg.sender == offer.counterparty, ErrorBuyOfferNotTaker());
            deposit = offer.takerDeposit;
            offer.takerDeposit = 0;
        } else if (OfferType.SELL == offer.type_) {
            require(
                !offer.funded,
                ErrorSellOfferCannotClaimDepositOfFundedOffer()
            );
            require(
                block.timestamp > offer.t1 ||
                    OfferState.REFUNDED == offer.state,
                ErrorSellOfferNotAfterT1OrRefunded()
            );
            // This is tested for safety, it should never happen
            require(
                OfferState.READY == offer.state ||
                    OfferState.TAKEN == offer.state ||
                    OfferState.REFUNDED == offer.state,
                ErrorSellOfferInvalidStateForClaimDeposit()
            );
            require(msg.sender == offer.owner, ErrorSellOfferNotOwner());
            deposit = offer.deposit;
            offer.deposit = 0;
        } else {
            revert ErrorInvalidOffer();
        }

        if (0 == deposit) {
            return;
        }

        liability -= deposit;

        // Attempt to refund the deposit
        (bool res, ) = payable(msg.sender).call{value: deposit}("");
        require(res, ErrorUnableToClaimDeposit());
    }

    ///
    /// FundingRequest related functions
    ///
    // ################################################################################

    /// Create a funding request
    /// @param amount requested funding amount (in wei)
    /// @param fee reward offered to the funder in case the funded amount was used in a successfully completed sell offer (in wei)
    function createFundingRequest(uint256 amount, uint256 fee) external {
        //
        // If msg.sender already has an active FundingRequest, the call fails
        //

        require(
            address(0) == fundingRequests[msg.sender].requester,
            ErrorFundingRequestAlreadyExistsForAddress()
        );

        //
        // If msg.sender has a balance above the configured threshold, no FundingRequest can be created
        //

        if (PARAMETERS.FUNDING_REQUEST_MAXBALANCE > 0) {
            require(
                msg.sender.balance <= PARAMETERS.FUNDING_REQUEST_MAXBALANCE,
                ErrorFundingRequestBalanceTooHigh(
                    msg.sender.balance,
                    PARAMETERS.FUNDING_REQUEST_MAXBALANCE
                )
            );
        }

        //
        // Only EOAs can request funding (see EIP-1052)
        // TODO(hbs): we may need to adapt this post Pectra upgrade since EIP-7702 is now live
        // As of now post Pectra, EOAs with a delegation will not be able to request funding
        //

        require(
            bytes32(
                0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
            ) == msg.sender.codehash,
            ErrorFundingRequestNotAnEOA()
        );

        // Check that amount is > 0
        require(amount > 0, ErrorFundingRequestZero());

        // Check that the fee is above the minimum fee
        require(
            fee >=
                ((PARAMETERS.FUNDING_REQUEST_MIN_FEE_RATIO * amount) /
                    RATIO_DENOMINATOR),
            ErrorFundingRequestFeeBelowMinimumRatio(
                PARAMETERS.FUNDING_REQUEST_MIN_FEE_RATIO
            )
        );

        // Ensure the requested amount is greater or equal to the fee so the funder can be paid
        require(amount >= fee, ErrorFundingRequestAmountBelowFee());

        //
        // TODO(hbs) if msg.sender has a buy or sell offer, no FundingRequest can be requested?
        //

        FundingRequest memory freq;
        freq.requester = msg.sender;
        freq.amount = amount;
        freq.fee = fee;
        freq.funder = address(0);
        freq.fundedOn = 0;

        //
        // Add the FundingRequest to the mapping
        //
        fundingRequests[msg.sender] = freq;

        //
        // Add the requester of the FundingRequest at the end of the array of active requesters
        //

        // Update the index, note that we do not use freq but the mapping entry directly as freq is in memory and was copied
        fundingRequests[msg.sender].index = activeFundingRequesters.length;
        activeFundingRequesters.push(msg.sender);

        emit FundingEvent(freq.requester, freq.amount, freq.fee);
    }

    /// Get the details of a funding request created by a specific address
    /// @param requester address for which to retrieve the funding request
    function getFundingRequest(
        address requester
    ) public view returns (FundingRequest memory) {
        FundingRequest storage freq = fundingRequests[requester];
        require(freq.requester == requester, ErrorFundingRequestNotFound());
        return freq;
    }

    /// Returns a slice of the active FundingRequests.
    /// As for listBuyOffers and listSellOffers, pagination may miss results or return duplicated across calls if funding requests were removed in the interval.
    /// @param offset offset where to start the pagination in the list of funding requests
    /// @param count number of funding requests to return
    function listFundingRequests(
        uint offset,
        uint count
    ) public view returns (FundingRequest[] memory) {
        // If the offset is past the end of the array, set count to 0
        if (offset >= activeFundingRequesters.length) {
            count = 0;
        } else {
            uint256 c = activeFundingRequesters.length - offset;
            if (c < count) {
                count = c;
            }
        }

        FundingRequest[] memory result = new FundingRequest[](count);

        for (uint i = offset; i < offset + count; i++) {
            result[i - offset] = fundingRequests[activeFundingRequesters[i]];
        }

        return result;
    }

    /// Fund a FundingRequest.
    /// The exact amount requested in the funding request must be sent alongside the call to this function.
    /// @param requester address of the requester whose funding request the caller wants to fund
    function fundFundingRequest(address requester) public payable {
        FundingRequest storage freq = fundingRequests[requester];

        require(address(0) == freq.funder, ErrorFundingRequestAlreadyFunded());
        require(
            msg.sender != freq.requester,
            ErrorFundingRequestCannotSelfFund()
        );
        require(freq.amount > 0, ErrorFundingRequestNotFound());
        require(
            msg.value == freq.amount,
            ErrorFundingRequestIncorrectAmount(msg.value, freq.amount)
        );

        freq.funder = msg.sender;
        freq.fundedOn = block.timestamp;

        //
        // Update liability
        //
        liability += msg.value;
    }

    /// Cancel a FundingRequest. This can be called by the requester BEFORE the request is funded
    function cancelFundingRequest() public {
        FundingRequest memory freq = fundingRequests[msg.sender];

        require(
            address(0) == freq.funder,
            ErrorFundingRequestCurrentlyFunded()
        );

        if (msg.sender == freq.requester) {
            address lastfreq = activeFundingRequesters[
                activeFundingRequesters.length - 1
            ];
            activeFundingRequesters[freq.index] = lastfreq;
            fundingRequests[lastfreq].index = freq.index;
            activeFundingRequesters.pop();
            delete fundingRequests[msg.sender];
        }
    }

    /// Defund a FundingRequest. This can be called by a funder BEFORE the funding is used.
    /// @param addr address of the creator of the funding request
    function defundFundingRequest(address addr) public nonReentrant {
        FundingRequest storage freq = fundingRequests[addr];

        require(0 == freq.usedby, ErrorFundingRequestInUse());

        require(
            msg.sender == freq.funder,
            ErrorFundingRequestDefundableOnlyByFunder()
        );

        // Set the funder to 0 and send the funded amount back to the funder
        freq.funder = address(0);
        freq.fundedOn = 0;

        liability -= freq.amount;

        (bool res, ) = payable(msg.sender).call{value: freq.amount}("");
        require(res, ErrorFundingRequestUnableToRefund());
    }

    /// Claim a FundingRequest. This can be called by a funder or a fundee of a FundingRequest that has been
    /// used AFTER the offer in which it was used was put in the READY state or its timestamp t0 has passed.
    /// This function exists to ensure that the funder can get its money back even if the funded
    /// account never claims the offer in which the funded funding request was used. Or if the call to claim failed to send funds back to the funder.
    /// In normal situations the fee should be paid during the call to claim.
    /// @param addr address of the creator of the funding request
    function claimFundingRequest(address addr) public nonReentrant {
        FundingRequest storage freq = fundingRequests[addr];

        require(
            msg.sender == freq.funder || msg.sender == addr,
            ErrorFundingRequestClaimableOnlyByFunderOrFundee()
        );
        require(0 != freq.usedby, ErrorFundingRequestNotInUse());

        Offer memory offer = buyOffers[freq.usedby];

        if (OfferType.INVALID == offer.type_) {
            // Offer was not a buy offer, check sell offers
            offer = sellOffers[freq.usedby];
        }

        // This test failing would indicate a bug elsewhere in the contract, it is there as a safety measure
        require(OfferType.INVALID != offer.type_, ErrorInvalidOffer());

        // The funding request can be claimed only if the offer is in the READY state or
        // if the offer is in the TAKEN state and the timestamp is after t0

        require(
            OfferState.READY == offer.state ||
                OfferState.CLAIMED == offer.state ||
                (OfferState.TAKEN == offer.state && block.timestamp > offer.t0),
            ErrorFundingRequestNotClaimable()
        );

        uint256 amount = freq.amount;

        // If the offer is CLAIMED, the call will claim the fee too
        // This is to cover the case when the call to claim failed to send the fee back to the funder
        if (OfferState.CLAIMED == offer.state) {
            amount = amount + freq.fee;
            freq.fee = 0;
        }

        liability -= amount;

        // Clear the amount of the FundingRequest, if the offer is claimed, only the fee will then be paid
        freq.amount = 0;

        if (amount > 0) {
            (bool res, ) = payable(freq.funder).call{value: amount}("");
            require(res, ErrorFundingRequestUnableToRefund());

            // If the offer was CLAIMED, delete the funding request after a successful payment
            if (OfferState.CLAIMED == offer.state) {
                delete fundingRequests[addr];
            }
        }
    }

    ///
    /// Return the current liability of the contract, in wei.
    /// The liability is the total amount held by the contract which belongs to participants (fundings for funding requests, deposits for both sell and buy offers).
    ///
    function getLiability() public view returns (uint256) {
        return liability;
    }

    /// Function which checks if a key has already been used and would not be accepted
    /// when creating or taking an offer
    function isKeyUsed(uint256 key) public view returns (bool) {
        return usedPublicKeys[key];
    }

    /// Retrieve the market parameters
    function getParameters() public view returns (Parameters memory) {
        return PARAMETERS;
    }

    /// Set the market parameters
    function setParameters(
        uint256 FundingRequestMaxBalance, // in wei
        uint256 FundingRequestMinFeeRatio, // ratio multipled by RATIO_DENOMINATOR
        uint256 MaximumBuyOfferBookSize,
        uint256 MinimumBuyOffer, // in wei
        uint256 MaximumBuyOffer, // in wei
        uint256 MaximumSellOfferBookSize,
        uint256 MinimumSellOffer, // in wei
        uint256 MaximumSellOffer, // in wei
        uint256 SellOfferCoverageRatio, // ratio multiplied by RATIO_DENOMINATOR
        uint256 T0Delay, // in seconds
        uint256 T1Delay // in seconds
    ) public {
        require(msg.sender == owner, ErrorNotOwner());

        PARAMETERS.FUNDING_REQUEST_MAXBALANCE = FundingRequestMaxBalance;
        PARAMETERS.FUNDING_REQUEST_MIN_FEE_RATIO = FundingRequestMinFeeRatio;
        PARAMETERS.MAXIMUM_BUY_OFFER_BOOK_SIZE = MaximumBuyOfferBookSize;
        PARAMETERS.MINIMUM_BUY_OFFER = MinimumBuyOffer;
        PARAMETERS.MAXIMUM_BUY_OFFER = MaximumBuyOffer;
        PARAMETERS.MAXIMUM_SELL_OFFER_BOOK_SIZE = MaximumSellOfferBookSize;
        PARAMETERS.MINIMUM_SELL_OFFER = MinimumSellOffer;
        PARAMETERS.MAXIMUM_SELL_OFFER = MaximumSellOffer;
        PARAMETERS.SELL_OFFER_COVERAGE_RATIO = SellOfferCoverageRatio;

        require(
            T0Delay >= MINIMUM_DELAY,
            ErrorDelayTooShort(T0Delay, MINIMUM_DELAY)
        );
        require(
            T1Delay >= MINIMUM_DELAY,
            ErrorDelayTooShort(T1Delay, MINIMUM_DELAY)
        );

        PARAMETERS.T0_DELAY = T0Delay;
        PARAMETERS.T1_DELAY = T1Delay;
    }
}
