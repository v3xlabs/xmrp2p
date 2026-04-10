// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import {OfferState, OfferType} from "../../src/Enums.sol";
import {Utils} from "./Utils.t.sol";

/// Shared fixtures for XMRP2P forge tests.
abstract contract XMRP2PTestBase is Test {
    uint256 internal constant TRADE_AMOUNT = 1 ether;
    uint256 internal constant DEPOSIT_RATIO = 1000;
    uint256 internal constant REQUIRED_DEPOSIT = (TRADE_AMOUNT * DEPOSIT_RATIO) / 10_000;
    uint256 internal constant TRADE_PRICE = 150;
    uint256 internal constant STARTING_BALANCE = 10 ether;

    struct OfferKeys {
        uint256 evmPrivateViewKey;
        uint256 evmPrivateSpendKey;
        uint256 evmPublicViewKey;
        uint256 evmPublicSpendKey;
        uint256 xmrPrivateViewKey;
        uint256 xmrPrivateSpendKey;
        uint256 xmrPublicViewKey;
        uint256 xmrPublicSpendKey;
    }

    XMRP2P internal exchange;
    address internal admin;
    address internal buyer;
    address internal seller;

    function setUp() public virtual {
        admin = makeAddr("admin");
        buyer = makeAddr("buyer");
        seller = makeAddr("seller");

        vm.deal(buyer, STARTING_BALANCE);
        vm.deal(seller, STARTING_BALANCE);

        exchange = new XMRP2P(
            XMRP2P.Parameters({
                MINIMUM_OFFER: 0.00001 ether,
                MAXIMUM_OFFER: 10 ether,
                DEPOSIT_RATIO: DEPOSIT_RATIO,
                MAXIMUM_OFFER_BOOK_SIZE: 100,
                T0_DELAY: 24 hours,
                T1_DELAY: 24 hours
            }),
            admin
        );
    }

    function _offerSnapshot(uint256 offer_number) internal view returns (XMRP2P.Offer memory) {
        return exchange.listOffers(offer_number, 1, false)[0];
    }

    function _generateOfferKeys() internal returns (OfferKeys memory swapKeys) {
        (
            swapKeys.evmPrivateViewKey,
            swapKeys.evmPrivateSpendKey,
            swapKeys.evmPublicViewKey,
            swapKeys.evmPublicSpendKey,
            swapKeys.xmrPrivateViewKey,
            swapKeys.xmrPrivateSpendKey,
            swapKeys.xmrPublicViewKey,
            swapKeys.xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);
    }
}
