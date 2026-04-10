// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {XMRP2P} from "../../src/XMRP2P.sol";
import {OfferState, OfferType} from "../../src/Enums.sol";
import {Utils} from "./Utils.t.sol";
import {XMRP2PTestBase} from "./XMRP2PTestBase.t.sol";

contract XMRP2POrderFlowTest is XMRP2PTestBase {
    function testBuyOrderHappyPath() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), swapKeys.evmPublicSpendKey, swapKeys.evmPublicViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;
        XMRP2P.Offer memory createdOffer = _offerSnapshot(offer_number);

        assertEq(uint256(createdOffer.kind), uint256(OfferType.BUY));
        assertEq(uint256(createdOffer.state), uint256(OfferState.OPEN));
        assertEq(exchange.liability(), TRADE_AMOUNT);

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_number, swapKeys.xmrPublicSpendKey, swapKeys.xmrPrivateViewKey);

        XMRP2P.Offer memory takenOffer = _offerSnapshot(offer_number);
        assertEq(uint256(takenOffer.state), uint256(OfferState.TAKEN));
        assertEq(takenOffer.counterparty, seller);
        assertEq(exchange.liability(), TRADE_AMOUNT + REQUIRED_DEPOSIT);

        vm.prank(buyer);
        exchange.ready(offer_number);

        XMRP2P.Offer memory readyOffer = _offerSnapshot(offer_number);
        assertEq(uint256(readyOffer.state), uint256(OfferState.READY));

        vm.prank(seller);
        exchange.claim(offer_number, swapKeys.xmrPrivateSpendKey);

        XMRP2P.Offer memory claimedOffer = _offerSnapshot(offer_number);
        assertEq(uint256(claimedOffer.state), uint256(OfferState.CLAIMED));
        assertEq(claimedOffer.xmrPrivateSpendKey, swapKeys.xmrPrivateSpendKey);
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore - TRADE_AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore + TRADE_AMOUNT);
        Utils.checkLiability(address(exchange));
    }

    function testBuyOrderCanBeCancelledByMaker() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 buyerBalanceBefore = buyer.balance;

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), swapKeys.evmPublicSpendKey, swapKeys.evmPublicViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.cancel(offer_number);

        XMRP2P.Offer memory cancelledOffer = _offerSnapshot(offer_number);
        assertEq(uint256(cancelledOffer.state), uint256(OfferState.CANCELLED));
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore);
        Utils.checkLiability(address(exchange));
    }

    function testBuyOrderCanBeExitedByBuyer() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), swapKeys.evmPublicSpendKey, swapKeys.evmPublicViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_number, swapKeys.xmrPublicSpendKey, swapKeys.xmrPrivateViewKey);

        vm.prank(buyer);
        exchange.quit(offer_number, swapKeys.evmPrivateSpendKey, swapKeys.evmPrivateViewKey);

        XMRP2P.Offer memory refundedOffer = _offerSnapshot(offer_number);
        assertEq(uint256(refundedOffer.state), uint256(OfferState.REFUNDED));
        assertEq(refundedOffer.evmPrivateSpendKey, swapKeys.evmPrivateSpendKey);
        assertEq(refundedOffer.evmPrivateViewKey, swapKeys.evmPrivateViewKey);
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore);
        assertEq(seller.balance, sellerBalanceBefore);
        Utils.checkLiability(address(exchange));
    }

    function testSellOrderHappyPath() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), swapKeys.xmrPublicSpendKey, swapKeys.xmrPrivateViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;
        XMRP2P.Offer memory createdOffer = _offerSnapshot(offer_number);

        assertEq(uint256(createdOffer.kind), uint256(OfferType.SELL));
        assertEq(uint256(createdOffer.state), uint256(OfferState.OPEN));
        assertEq(exchange.liability(), REQUIRED_DEPOSIT);

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_number, swapKeys.evmPublicSpendKey, swapKeys.evmPublicViewKey);

        XMRP2P.Offer memory takenOffer = _offerSnapshot(offer_number);
        assertEq(uint256(takenOffer.state), uint256(OfferState.TAKEN));
        assertEq(takenOffer.counterparty, buyer);
        assertEq(exchange.liability(), TRADE_AMOUNT + REQUIRED_DEPOSIT);

        vm.prank(buyer);
        exchange.ready(offer_number);

        XMRP2P.Offer memory readyOffer = _offerSnapshot(offer_number);
        assertEq(uint256(readyOffer.state), uint256(OfferState.READY));

        vm.prank(seller);
        exchange.claim(offer_number, swapKeys.xmrPrivateSpendKey);

        XMRP2P.Offer memory claimedOffer = _offerSnapshot(offer_number);
        assertEq(uint256(claimedOffer.state), uint256(OfferState.CLAIMED));
        assertEq(claimedOffer.xmrPrivateSpendKey, swapKeys.xmrPrivateSpendKey);
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore - TRADE_AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore + TRADE_AMOUNT);
        Utils.checkLiability(address(exchange));
    }

    function testSellOrderCanBeCancelledByMaker() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), swapKeys.xmrPublicSpendKey, swapKeys.xmrPrivateViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.cancel(offer_number);

        XMRP2P.Offer memory cancelledOffer = _offerSnapshot(offer_number);
        assertEq(uint256(cancelledOffer.state), uint256(OfferState.CANCELLED));
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(seller.balance, sellerBalanceBefore);
        Utils.checkLiability(address(exchange));
    }

    function testSellOrderCanBeExitedByBuyer() public {
        OfferKeys memory swapKeys = _generateOfferKeys();
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), swapKeys.xmrPublicSpendKey, swapKeys.xmrPrivateViewKey
        );
        uint256 offer_number = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_number, swapKeys.evmPublicSpendKey, swapKeys.evmPublicViewKey);

        // Sell offers cannot be exited in the same block they were taken.
        vm.roll(block.number + 1);

        vm.prank(buyer);
        exchange.quit(offer_number, swapKeys.evmPrivateSpendKey, swapKeys.evmPrivateViewKey);

        XMRP2P.Offer memory refundedOffer = _offerSnapshot(offer_number);
        assertEq(uint256(refundedOffer.state), uint256(OfferState.REFUNDED));
        assertEq(refundedOffer.evmPrivateSpendKey, swapKeys.evmPrivateSpendKey);
        assertEq(refundedOffer.evmPrivateViewKey, swapKeys.evmPrivateViewKey);
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore);
        assertEq(seller.balance, sellerBalanceBefore);
        Utils.checkLiability(address(exchange));
    }
}
