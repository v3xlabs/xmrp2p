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

/// @title A XMRP2P contract for performing Atomic swaps between the native currency of an EVM based blockchain and Monero
/// @author v3xlabs
/// @notice special credit to hbs for the original implementation
/// @notice Use this contract responsibly
contract XMRP2P {
    enum OfferType {
        INVALID, // Used so the default value 0 is invalid
        BUY,
        SELL
    }

    enum OfferState {
        INVALID, // Used so the default value 0 is invalid
        OPEN, // Open offers are those still seeking a counterparty
        TAKEN, // Taken offers are those with both a buyer and a seller
        CANCELLED, // Cancelled offers are those no longer valid
        REFUNDED, // Refunded offers are those for which the buyer requested a refund
        READY, // Ready offers are those for which the Monero deposit was confirmed by the buyer
        CLAIMED, // Claimed offers are those whose Monero seller has claimed the amount of EVM currency paid for its XMR
        UPDATING // This is a temporary state during offer parameters update
    }

    /// The Offer structure is used to describe both buy and sell offers
    struct Offer {
        /// Type of offer
        OfferType type_;
        /// State of the offer
        OfferState state;
        /// Owner of the offer, the address which called create{Buy,Sell}Offer
        address owner;
        /// Counterparty of the offer. This can be set at creation time, in which case only that counterparty can take the offer,
        /// or will be filled when the offer is taken.
        address counterparty;
        /// Id of the offer
        uint256 id;
        /// Maximum trade amount (in wei). This is set from the value transfered during the call to create{Buy,Sell}Offer
        /// and updated by calls to update{Buy,Sell}Offer
        uint256 amount;
        /// Fixed price of the offer, in wei per XMR.
        uint256 price;
        /// Timestamp when the offer was created or last updated (so users can asses of its freshness)
        uint256 lastupdate;
        /// Block number when the offer was taken. This is needed so retrieving messages can be done from a specific block.
        uint256 blockTaken;
        /// Monero public spend key of the EVM side of the trade
        uint256 evmPublicSpendKey;
        /// Monero private spend key of the EVM side of the trade. Set during a call to refund.
        uint256 evmPrivateSpendKey;
        /// Public view key provided by the EVM side of the trade. This is needed to compute the Monero address
        /// and to verify the private view key during a refund as the private view key may have been generated in a non standard way
        uint256 evmPublicViewKey;
        /// Monero private view key of the EVM side of the trade. Set during a call to refund.
        uint256 evmPrivateViewKey;
        /// Monero public spend key of the XMR side of the trade
        uint256 xmrPublicSpendKey;
        /// Monero private spend key of the XMR side of the trade. Set during a call to claim
        uint256 xmrPrivateSpendKey;
        /// Monero private view key of the XMR side of the trade. The EVM side of the trade doesn't need to share its private view key.
        uint256 xmrPrivateViewKey;
        /// Timestamp until which 'ready' can be called, after, taken offer is considered in the READY state
        uint256 t0;
        /// Timestamp after which 'claim' can be called, after, taken offer can be refunded
        uint256 t1;
    }

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
    /// Those parameters may be set by the constructor or via the setParameters / setPriceOracle / setSavingsXDAIParameters functions
    struct Parameters {
        /// Minimum buy offer (in wei)
        uint256 MINIMUM_BUY_OFFER;
        /// Maximum buy offer (in wei)
        uint256 MAXIMUM_BUY_OFFER;
        /// Minimum sell offer (in wei)
        uint256 MINIMUM_SELL_OFFER;
        /// Maximum sell offer (in wei)
        uint256 MAXIMUM_SELL_OFFER;
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

    Parameters public PARAMETERS;

    ///
    /// Total liability of the contract (in wei). This includes deposits for Buy and Sell offers
    /// and funds funding FundingRequests.
    ///
    /// The total liability is used to compute how much of the optionally accrued interests (from sDAI deposits) can
    /// be withdrawn.
    uint256 public liability;

    /// Id of the next Offer to create. This is common to both Buy and Sell offers.
    uint256 public nextOfferId = 1;

    /// Mapping from buy offer id to buy offer
    mapping(uint256 => Offer) public offers;

    /// Mapping of used public keys. This is kept track of so
    /// a public key cannot be reused as a public spend key, otherwise, if an offer which used
    /// a key has been completed, the associated private key might have been
    /// revealed which would compromise the security.
    /// Entries for public view keys and public message keys are also added. This adds a cost to
    /// createSellOffer and takeBuyOffer functions as an Ed25519 scalarmult must be performed to
    /// generate the publicViewKey from the privateViewKey, but this is for security reasons.
    mapping(uint256 => bool) public usedPublicKeys;

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

    constructor() payable {
        // No value is accepted since it cannot be withdrawn
        require(0 == msg.value);
        PARAMETERS.T0_DELAY = 24 * 3600;
        PARAMETERS.T1_DELAY = 24 * 3600;
        PARAMETERS.MINIMUM_BUY_OFFER = 1_000_000_000 gwei; // 1 xDAI
        PARAMETERS.MAXIMUM_BUY_OFFER = 1_000_000_000_000 ether; // 1 trillion xDAI
        PARAMETERS.MINIMUM_SELL_OFFER = 1_000_000_000 gwei; // 1 xDAI
        PARAMETERS.MAXIMUM_SELL_OFFER = 1_000_000_000_000 ether; // 1 trillion xDAI
        PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE = 1_000_000;
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
    /// @param price The (fixed) price of the offer.
    /// @param counterparty The address of a designated counterparty for the offer. Set to 0 to allow offer to be taken by any address.
    /// @param amount
    /// @param publicspendkey The Monero public spend key.
    /// @param publicviewkey The Monero public view key.
    ///
    function createBuyOffer(uint256 price, address counterparty, uint256 publicspendkey, uint256 publicviewkey)
        public
        payable
    {
        //
        // Check if maximum number of active offers is reached
        //
        require(
            0 == PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE || offers.length < PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE,
            ErrorMaximumOfferBookSizeReached(offers.length)
        );

        //
        // Check if the Monero public spend key has been used. First add the public view/message keys.
        //
        usedPublicKeys[publicviewkey] = true;
        require(!usedPublicKeys[publicspendkey], ErrorBuyOfferPublicSpendKeyAlreadyUsed());
        usedPublicKeys[publicspendkey] = true;

        //
        // Sent amount MUST be >= MINIMUM_BUY_OFFER
        //
        require(
            msg.value >= PARAMETERS.MINIMUM_BUY_OFFER, ErrorBuyOfferAmountBelowMinimum(PARAMETERS.MINIMUM_BUY_OFFER)
        );
        require(
            msg.value <= PARAMETERS.MAXIMUM_BUY_OFFER, ErrorBuyOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_BUY_OFFER)
        );

        Offer memory offer;

        offer.type_ = OfferType.BUY;
        offer.id = nextOfferId++;
        offer.state = OfferState.OPEN;
        offer.lastupdate = block.timestamp;
        offer.owner = msg.sender;
        offer.counterparty = counterparty;
        offer.amount = msg.value;
        offer.price = price;
        offer.evmPublicSpendKey = publicspendkey;
        offer.evmPublicViewKey = publicviewkey;

        offers[offer.id] = offer;

        //
        // Update the liability
        //
        liability += msg.value;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Update an existing buy offer. The owner can update the offer.
    /// @param id the id of the offer to update
    /// @param price fixed price at which the buyer is willing to buy Monero (in wei per Monero). If 0, the price will be determined by the oracle
    /// @param counterparty address of explicit counterparty. Use 0x0 to allow any account to take the offer
    function updateBuyOffer(uint256 id, uint256 price, address counterparty) public payable nonReentrant {
        Offer storage offer = offers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(msg.sender == offer.owner, ErrorBuyOfferInvalidCallerForUpdate());

        require(OfferState.OPEN == offer.state, ErrorBuyOfferInvalidStateForUpdate(offer.state));

        if (counterparty != offer.counterparty) {
            // TODO: this should not be allowed if the offer is accepted
            offer.counterparty = counterparty;
        }

        offer.lastupdate = block.timestamp;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Take a buy offer. This is called by someone providing Monero. It will determine the offer counterparty and will set timestamps t0 and t1.
    ///
    /// @param id The id of the buy offer to take
    /// @param publicspendkey Monero Public spend key
    /// @param privateviewkey Monero Private view key
    ///
    function takeBuyOffer(uint256 id, uint256 publicspendkey, uint256 privateviewkey) public payable nonReentrant {
        // Ensure the buy offer exists and is not yet taken
        Offer storage offer = offers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(OfferState.OPEN == offer.state, ErrorBuyOfferInvalidStateForTake(offer.state));

        require(
            address(0) == offer.counterparty || offer.counterparty == msg.sender, ErrorBuyOfferInvalidCounterparty()
        );

        // If no deposit was sent (msg.value is 0), check for a valid funded FundingRequest
        // TODO: handle this
        offer.deposit = msg.value;

        // Compute the public view key associated with the provided private view key and add it
        // to the usedPublicKeys mapping. This is a costly operation but it adds security.

        (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateviewkey);
        uint256 publicviewkey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));
        usedPublicKeys[publicviewkey] = true;

        // Ensure the provided public key has not yet been used
        require(!usedPublicKeys[publicspendkey], ErrorBuyOfferPublicSpendKeyAlreadyUsed());
        usedPublicKeys[publicspendkey] = true;

        offer.counterparty = msg.sender;
        offer.blockTaken = block.number;
        offer.xmrPublicSpendKey = publicspendkey;
        offer.xmrPrivateViewKey = privateviewkey;
        offer.state = OfferState.TAKEN;
        offer.lastupdate = block.timestamp;

        // Set milestones
        offer.t0 = block.timestamp + PARAMETERS.T0_DELAY;
        offer.t1 = offer.t0 + PARAMETERS.T1_DELAY;

        liability += msg.value;

        //
        // Emit an offer event
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Cancel a buy offer.
    /// @param id id of the offer to cancel
    function cancelBuyOffer(uint256 id) public nonReentrant {
        Offer storage offer = offers[id];

        require(OfferType.BUY == offer.type_, ErrorBuyOfferUnknown());

        require(offer.owner == msg.sender, ErrorBuyOfferNotOwner());
        require(OfferState.OPEN == offer.state, ErrorBuyOfferInvalidStateForCancel(offer.state));

        // Refund the offer owner
        liability -= offer.deposit;
        offer.state = OfferState.CANCELLED;
        offer.lastupdate = block.timestamp;
        (bool res,) = payable(offer.owner).call{value: offer.deposit}("");
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
    /// @param price fixed price, in wei per XMR. Use 0 if you want to use dynamic pricing
    /// @param amount amount of monero to sell
    /// @param publicspendkey Monero public spend key
    /// @param privateviewkey Monero private view key
    /// @param msgpubkey The public key to use for exchanging messages with the taker of the offer
    function createSellOffer(
        address counterparty,
        uint256 price,
        uint256 amount,
        uint256 publicspendkey,
        uint256 privateviewkey
    ) public payable {
        //
        // Check if maximum number of active offers is reached
        //
        require(
            0 == PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE || offers.length < PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE,
            ErrorMaximumOfferBookSizeReached(offers.length)
        );

        //
        // Check if the pubkey has been used. Add the public view and message keys
        //
        (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateviewkey);
        uint256 publicviewkey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));
        usedPublicKeys[publicviewkey] = true;
        require(!usedPublicKeys[publicspendkey], ErrorSellOfferPublicSpendKeyAlreadyUsed());
        usedPublicKeys[publicspendkey] = true;

        Offer memory offer;
        offer.id = nextOfferId++;

        offer.deposit = msg.value;
        liability += msg.value;

        //
        // Sent amount MUST be >= MINIMUM_SELL_OFFER
        //

        require(
            amount >= PARAMETERS.MINIMUM_SELL_OFFER, ErrorSellOfferAmountBelowMinimum(PARAMETERS.MINIMUM_SELL_OFFER)
        );
        require(
            amount <= PARAMETERS.MAXIMUM_SELL_OFFER, ErrorSellOfferAmountAboveMaximum(PARAMETERS.MAXIMUM_SELL_OFFER)
        );

        offer.type_ = OfferType.SELL;

        offer.state = OfferState.OPEN;
        offer.owner = msg.sender;
        offer.counterparty = counterparty;
        offer.lastupdate = block.timestamp;
        offer.maxamount = amount;
        offer.price = price;
        offer.oracleRatio = oracleRatio;
        offer.oracleOffset = oracleOffset;
        offer.minxmr = minxmr;
        offer.minprice = minprice;
        offer.maxxmr = maxxmr;
        offer.xmrPublicSpendKey = publicspendkey;
        offer.xmrPrivateViewKey = privateviewkey;
        offer.xmrPublicMsgKey = msgpubkey;

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
    function updateSellOffer(
        uint256 id,
        address counterparty,
        uint256 price,
        uint256 amount
    ) public payable {
        Offer storage offer = offers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());

        require(OfferState.OPEN == offer.state, ErrorSellOfferInvalidStateForUpdate(offer.state));

        require(msg.sender == offer.owner, ErrorSellOfferInvalidCallerForUpdate());

 
            // Adjust the deposit and maximum amount if value is non 0
            offer.deposit += msg.value;
            offer.maxamount = (offer.deposit * RATIO_DENOMINATOR) / PARAMETERS.SELL_OFFER_COVERAGE_RATIO;

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

        offer.counterparty = counterparty;
        offer.lastupdate = block.timestamp;

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    ///
    /// Take a sell offer. This will determine the counterparty and will set the timestamps t0 and t1.
    ///
    /// @param id id of the offer to take
    /// @param minxmr The minimum amount of piconeros that the taker wishes to acquire
    /// @param maxprice The maximum price per XMR (in wei) that the taker is willing to pay
    /// @param publicspendkey Monero public spend key generated by the taker
    /// @param publicviewkey Monero public view key generated by the taker
    /// @param msgpubkey Public key for exchanging messages (using ECDH to compute the encryption key) between the two parties of the offer
    function takeSellOffer(
        uint256 id,
        uint256 minxmr,
        uint256 maxprice,
        uint256 publicspendkey,
        uint256 publicviewkey,
        uint256 msgpubkey
    ) public payable nonReentrant {
        // Ensure the buy offer exists and is not yet taken
        Offer storage offer = sellOffers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());

        require(OfferState.OPEN == offer.state, ErrorSellOfferInvalidStateForTake(offer.state));

        require(
            address(0) == offer.counterparty || offer.counterparty == msg.sender, ErrorSellOfferInvalidCounterparty()
        );

        // Ensure the provided public key has not yet been used
        usedPublicKeys[publicviewkey] = true;
        bool usedMsgKey = usedPublicKeys[msgpubkey];
        usedPublicKeys[msgpubkey] = true;
        require(!usedPublicKeys[publicspendkey], ErrorSellOfferPublicSpendKeyAlreadyUsed());
        usedPublicKeys[publicspendkey] = true;

        require(0 == msgpubkey || !usedMsgKey, ErrorSellOfferUsedMessageKey());

        // Compute the buy offer current price (by querying the oracle if need be)
        // Price is in wei per XMR
        uint256 price = getXMRPrice(offer.type_, offer.price, offer.oracleRatio, offer.oracleOffset, maxprice);

        // Compute the amount of picoxmr the taker can buy (limited by the offer's maxamount)
        uint256 picoxmr = (((msg.value > offer.maxamount) ? offer.maxamount : msg.value) * UNITS_PER_XMR) / price;

        // Limit the buyable amount to the maximum provided by the offer
        if (picoxmr > offer.maxxmr) {
            picoxmr = offer.maxxmr;
        }

        // Ensure that the taker can buy the the minimum amount of XMR the maker requested
        require(picoxmr >= offer.minxmr, ErrorSellOfferXMRAmountBelowOfferMinimum(picoxmr, offer.minxmr));

        // Ensure that the transaction would buy at least the amount of XMR requested by the taker
        require(picoxmr >= minxmr, ErrorSellOfferXMRAmountTooLow(picoxmr, minxmr));

        // Compute the amount to be spent by the taker
        uint256 amount = (picoxmr * price) / UNITS_PER_XMR;

        // Amount must be <= maxamount, otherwise a deposit lower than the required ratio could be used by the seller
        // Given the way picoxmr is computed, this should always be true
        require(amount <= offer.maxamount, ErrorSellOfferAmountAboveMaximum(offer.maxamount));

        // This is here for safety, but given the way picoxmr is computed it should never happen except maybe due to rounding errors
        require(amount <= msg.value, ErrorSellOfferAmountAboveMaximum(msg.value));

        /// If the offer was funded, ensure the settlement amount is enough to cover the funding fee
        if (offer.funded) {
            FundingRequest storage freq = fundingRequests[offer.owner];
            require(amount >= freq.fee, ErrorSellOfferAmountTooLowToCoverFundingFee());
        }

        offer.counterparty = msg.sender;
        offer.blockTaken = block.number;

        offer.evmPublicSpendKey = publicspendkey;
        offer.evmPublicViewKey = publicviewkey;
        offer.evmPublicMsgKey = msgpubkey;
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
            (bool res,) = payable(msg.sender).call{value: msg.value - amount}("");
            require(res, ErrorSellOfferUnableToSendAmountDelta());
        }

        //
        // Emit an OfferEvent
        //
        emit OfferEvent(offer.id, offer.type_, offer.state);
    }

    /// Cancel a sell offer.
    /// A sell offer can be cancelled by its owner but in the case it was funded by a third party it can
    /// also be cancelled by the funder after a delay so the funder is not at risk of not being able to
    /// recover its funds due to a stale OPEN offer which is never taken.
    /// @param id id of the offer to cancel
    function cancelSellOffer(uint256 id) public nonReentrant {
        Offer storage offer = sellOffers[id];

        require(OfferType.SELL == offer.type_, ErrorSellOfferUnknown());
        require(OfferState.OPEN == offer.state, ErrorSellOfferInvalidStateForCancel(offer.state));

        FundingRequest storage freq = fundingRequests[offer.owner];

        if (offer.owner != msg.sender) {
            require(
                offer.funded && offer.id == freq.usedby && msg.sender == freq.funder
                    && block.timestamp > freq.fundedOn + 2 * (PARAMETERS.T0_DELAY + PARAMETERS.T1_DELAY),
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

            (bool res,) = payable(offer.owner).call{value: offer.deposit}("");
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
            require(OfferState.TAKEN == offer.state, ErrorBuyOfferInvalidStateForReady(offer.state));
            require(msg.sender == offer.owner, ErrorBuyOfferNotOwner());
            require(block.timestamp <= offer.t0, ErrorBuyOfferAfterT0());
        } else if (OfferType.SELL == offer.type_) {
            require(OfferState.TAKEN == offer.state, ErrorSellOfferInvalidStateForReady(offer.state));
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
                require(block.timestamp > offer.t0 && block.timestamp <= offer.t1, ErrorBuyOfferNotBetweenT0AndT1());
            } else if (OfferState.READY == offer.state) {
                require(block.timestamp <= offer.t1, ErrorBuyOfferAfterT1());
            } else {
                revert ErrorBuyOfferInvalidStateForClaim(offer.state);
            }
            require(msg.sender == offer.counterparty, ErrorBuyOfferNotTaker());
            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.xmrPublicSpendKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidXMRPrivateSpendKey()
            );
            offer.xmrPrivateSpendKey = privateSpendKey;
            freq = fundingRequests[offer.counterparty];
        } else if (OfferType.SELL == offer.type_) {
            if (OfferState.TAKEN == offer.state) {
                require(block.timestamp > offer.t0 && block.timestamp <= offer.t1, ErrorSellOfferNotBetweenT0AndT1());
            } else if (OfferState.READY == offer.state) {
                require(block.timestamp <= offer.t1, ErrorSellOfferAfterT1());
            } else {
                revert ErrorSellOfferInvalidStateForClaim(offer.state);
            }
            require(msg.sender == offer.owner, ErrorSellOfferNotOwner());
            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.xmrPublicSpendKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
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

        uint256 settlement = (offer.finalprice * offer.finalxmr) / UNITS_PER_XMR;
        uint256 payToClaimer = settlement;

        if (offer.funded && freq.usedby == offer.id) {
            //
            // Delete FundingRequest
            //
            address lastfreq = activeFundingRequesters[activeFundingRequesters.length - 1];
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
                (bool fres,) = payable(freq.funder).call{value: payToFunder}("");
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
            (bool res,) = payable(msg.sender).call{value: payToClaimer}("");
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
    function refund(uint256 id, uint256 privateSpendKey, uint256 privateViewKey) public nonReentrant {
        Offer storage offer = buyOffers[id];

        if (OfferType.INVALID == offer.type_) {
            offer = sellOffers[id];
        }

        if (OfferType.BUY == offer.type_) {
            // If offer is in state TAKEN, then timestamp must either be <= t0 or > t1
            if (OfferState.TAKEN == offer.state) {
                require(block.timestamp <= offer.t0 || block.timestamp > offer.t1, ErrorBuyOfferBetweenT0AndT1());
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
                offer.evmPublicSpendKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidEVMPrivateSpendKey()
            );
            (x, y) = Ed25519.scalarMultBase(privateViewKey);
            require(
                offer.evmPublicViewKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorBuyOfferInvalidEVMPrivateViewKey()
            );
        } else if (OfferType.SELL == offer.type_) {
            // If offer is in state TAKEN, then timestamp must either be <= t0 or > t1
            // Also a taken offer cannot be refunded in the same block in which it was taken
            if (OfferState.TAKEN == offer.state) {
                require(block.number > offer.blockTaken, ErrorSellOfferCannotRefundInTakenBlock());
                require(block.timestamp <= offer.t0 || block.timestamp > offer.t1, ErrorSellOfferBetweenT0AndT1());
            } else if (OfferState.READY == offer.state) {
                // For READY state, timestamp must be > t1
                require(block.timestamp > offer.t1, ErrorSellOfferNotAfterT1());
            } else {
                // refund can only be called for offers in the READY or TAKEN state
                revert ErrorSellOfferInvalidStateForRefund(offer.state);
            }

            require(msg.sender == offer.counterparty, ErrorSellOfferNotCounterparty());

            (uint256 x, uint256 y) = Ed25519.scalarMultBase(privateSpendKey);
            require(
                offer.evmPublicSpendKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
                ErrorSellOfferInvalidEVMPrivateSpendKey()
            );
            (x, y) = Ed25519.scalarMultBase(privateViewKey);
            require(
                offer.evmPublicViewKey == Ed25519.changeEndianness(Ed25519.compressPoint(x, y)),
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
            (bool res,) = payable(msg.sender).call{value: offer.deposit}("");
            require(res, ErrorBuyOfferUnableToRefund());

            // Refund the taker's deposit
            if (offer.takerDeposit > 0) {
                uint256 takerDeposit = offer.takerDeposit;
                liability -= takerDeposit;
                offer.takerDeposit = 0;
                (res,) = payable(offer.counterparty).call{value: takerDeposit}("");
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
            (bool res,) = payable(msg.sender).call{value: offer.takerDeposit}("");
            require(res, ErrorSellOfferUnableToRefund());

            // Refund the seller's deposit if the offer was not financed by a funding request
            freq = fundingRequests[offer.owner];

            if (freq.usedby == offer.id && freq.requester == offer.owner) {
                freq.usedby = 0;
            } else if (offer.deposit > 0) {
                uint256 deposit = offer.deposit;
                liability -= deposit;
                offer.deposit = 0;
                (res,) = payable(offer.owner).call{value: deposit}("");
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
            require(!offer.funded, ErrorBuyOfferCannotClaimDepositOfFundedOffer());
            require(
                block.timestamp > offer.t1 || OfferState.REFUNDED == offer.state, ErrorBuyOfferNotAfterT1OrRefunded()
            );
            // This is tested for safety, it should never happen
            require(
                OfferState.READY == offer.state || OfferState.TAKEN == offer.state
                    || OfferState.REFUNDED == offer.state,
                ErrorBuyOfferInvalidStateForClaimDeposit()
            );
            require(msg.sender == offer.counterparty, ErrorBuyOfferNotTaker());
            deposit = offer.takerDeposit;
            offer.takerDeposit = 0;
        } else if (OfferType.SELL == offer.type_) {
            require(!offer.funded, ErrorSellOfferCannotClaimDepositOfFundedOffer());
            require(
                block.timestamp > offer.t1 || OfferState.REFUNDED == offer.state, ErrorSellOfferNotAfterT1OrRefunded()
            );
            // This is tested for safety, it should never happen
            require(
                OfferState.READY == offer.state || OfferState.TAKEN == offer.state
                    || OfferState.REFUNDED == offer.state,
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
        (bool res,) = payable(msg.sender).call{value: deposit}("");
        require(res, ErrorUnableToClaimDeposit());
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

    /// Set the market parameters
    function setParameters(
        uint256 MaximumOfferBookSize,
        uint256 MinimumBuyOffer, // in wei
        uint256 MaximumBuyOffer, // in wei
        uint256 MinimumSellOffer, // in wei
        uint256 MaximumSellOffer, // in wei
        uint256 T0Delay, // in seconds
        uint256 T1Delay // in seconds
    ) public {
        require(msg.sender == owner, ErrorNotOwner());

        PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE = MaximumOfferBookSize;
        PARAMETERS.MINIMUM_BUY_OFFER = MinimumBuyOffer;
        PARAMETERS.MAXIMUM_BUY_OFFER = MaximumBuyOffer;
        PARAMETERS.MINIMUM_SELL_OFFER = MinimumSellOffer;
        PARAMETERS.MAXIMUM_SELL_OFFER = MaximumSellOffer;

        require(T0Delay >= MINIMUM_DELAY, ErrorDelayTooShort(T0Delay, MINIMUM_DELAY));
        require(T1Delay >= MINIMUM_DELAY, ErrorDelayTooShort(T1Delay, MINIMUM_DELAY));

        PARAMETERS.T0_DELAY = T0Delay;
        PARAMETERS.T1_DELAY = T1Delay;
    }
}
