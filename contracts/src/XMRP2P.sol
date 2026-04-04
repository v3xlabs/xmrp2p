// SPDX-License-Identifier: MIT

pragma solidity ^0.8.34;

import {Ed25519} from "./Ed25519.sol";
import "./Errors.sol";
import "./Enums.sol";
import "./Structs.sol";
import { Ownable } from '../lib/solady/src/auth/Ownable.sol';

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
        CLAIMED // Claimed offers are those whose Monero seller has claimed the amount of EVM currency paid for its XMR
    }

    /// The Offer structure is used to describe both buy and sell offers
    struct Offer {
        uint256 id;
        OfferType kind;
        OfferState state;
        address owner;
        address counterparty;
        uint256 amount;
        uint256 price;
        uint256 lastupdate;
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

    /// Minimum T0 and T1 delays.
    /// Setting those delays too low can lead to funds being 'stolen' by giving the XMR side the possibility to
    /// call claim almost immediately if T0 is too low. After T0, a taken offer becomes claimable even if it was not
    /// put in the READY state by the EVM side. So in order to avoid this we constrain the T0 and T1 delays to be at least
    /// MINIMUM_DELAY seconds
    uint256 constant MINIMUM_DELAY = 24 * 3_600; // twenty-four hours

    uint256 public liability;
    uint256 public nextOfferId = 1;
    mapping(uint256 => Offer) public offers;
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

    event OfferEvent(
        uint256 offer_id,
        OfferType indexed kind,
        OfferState indexed state
    );

    constructor() payable {

    }

    /// Receive function safeguard
    receive() external payable {
        require(0 == msg.value, ErrorUnableToAcceptPayment());
    }

    /// Fallback function safeguard
    fallback() external payable {
        require(0 == msg.value, ErrorUnableToAcceptPayment());
    }

    _keySanity(uint256 pubKey) internal {
        require(!usedPublicKeys[pubKey], ErrorKeyAlreadyUsed());
        usedPublicKeys[pubKey] = true;
    }

    _offer(OfferType offerType, uint256 price, address counterparty, uint256 pubSpendKey, uint256 pubViewKey) internal {
        require(
            0 == PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE || offers.length < PARAMETERS.MAXIMUM_OFFER_BOOK_SIZE,
            ErrorMaximumOfferBookSizeReached(offers.length)
        );

        _keySanity(pubSpendKey);
        _keySanity(pubViewKey);

        uint256 evmAmount = offerType == OfferType.BUY ? msg.value : msg.value * (1/DEPOSIT_RATIO);
        uint256 deposit = offerType == evmAmount * DEPOSIT_RATIO;

        Offer memory offer;
        offer.kind = offerType;
        offer.id = nextOfferId++;
        offer.state = OfferState.OPEN;
        offer.lastupdate = block.timestamp;
        offer.owner = msg.sender;
        offer.counterparty = counterparty;
        offer.amount = evmAmount;
        offer.deposit = evmAmount * price;
        offer.price = price;

        liability += msg.value;

        return offer;
    }

    /// Create buy offer
    buy(uint256 price, address counterparty, uint256 pubSpendKey, uint256 pubViewKey) public payable {
        Offer memory offer = _offer(OfferType.BUY, price, counterparty, pubSpendKey, pubViewKey);
        offer.evmPublicSpendKey = spendKey;
        offer.evmPublicViewKey = viewKey;
        offers[offer.id] = offer;
    }

    /// Create sell offer
    sell(uint256 price, address counterparty, uint256 pubSpendKey, uint256 privViewKey) public payable {
        uint256 pubViewKey = '';
        _offer(OfferType.SELL, price, counterparty, pubSpendKey, pubViewKey);
        offer.xmrPublicSpendKey = pubSpendKey;
        offer.xmrPrivateViewKey = privViewKey;
        offers[offer.id] = offer;
    }
}
