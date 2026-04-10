// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {XMRP2P} from "../../src/XMRP2P.sol";
import {OfferState, OfferType} from "../../src/Enums.sol";
import {
    ErrorBuyOfferInvalidEVMPrivateSpendKey,
    ErrorClaimUnavailable,
    ErrorInvalidEVMPrivateViewKey,
    ErrorInvalidOfferStateForQuit,
    ErrorInvalidPrivateSpendKey,
    ErrorNonMember,
    ErrorSellOfferCannotQuitInTakenBlock
} from "../../src/Errors.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {Utils} from "./Utils.t.sol";
import {XMRP2PTestBase} from "./XMRP2PTestBase.t.sol";

/// Quit (`quit`) is the on-chain refund path: it moves the offer to `REFUNDED` and pays both parties.
/// These tests cover post-expiration quit, the forbidden mid-window, claim timeouts, and access/key checks.
contract XMRP2PQuitExpireSafetyTest is XMRP2PTestBase {
    function testBuyQuitAfterT1WhenTaken_RefundsBothParties() public {
        OfferKeys memory k = _generateOfferKeys();
        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t1 + 1);

        vm.prank(buyer);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.REFUNDED));
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBefore);
        assertEq(seller.balance, sellerBefore);
        Utils.checkLiability(address(exchange));
    }

    function testSellQuitAfterT1WhenTaken_RefundsBothParties() public {
        OfferKeys memory k = _generateOfferKeys();
        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);
        vm.roll(block.number + 1);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t1 + 1);

        vm.prank(buyer);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.REFUNDED));
        assertEq(exchange.liability(), 0);
        assertEq(address(exchange).balance, 0);
        assertEq(buyer.balance, buyerBefore);
        assertEq(seller.balance, sellerBefore);
        Utils.checkLiability(address(exchange));
    }

    function testBuyQuitAfterT1WhenReady_RefundsBothParties() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(buyer);
        exchange.ready(offer_id);

        XMRP2P.Offer memory readyOffer = _offerSnapshot(offer_id);
        vm.warp(readyOffer.t1 + 1);

        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.REFUNDED));
        assertEq(exchange.liability(), 0);
        assertEq(buyer.balance, buyerBefore + TRADE_AMOUNT);
        assertEq(seller.balance, sellerBefore + REQUIRED_DEPOSIT);
        Utils.checkLiability(address(exchange));
    }

    function testSellQuitAfterT1WhenReady_RefundsBothParties() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);
        vm.roll(block.number + 1);

        vm.prank(buyer);
        exchange.ready(offer_id);

        XMRP2P.Offer memory readyOffer = _offerSnapshot(offer_id);
        vm.warp(readyOffer.t1 + 1);

        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.REFUNDED));
        assertEq(exchange.liability(), 0);
        assertEq(buyer.balance, buyerBefore + TRADE_AMOUNT);
        assertEq(seller.balance, sellerBefore + REQUIRED_DEPOSIT);
        Utils.checkLiability(address(exchange));
    }

    function testBuyQuitRevertsWhenTakenBetweenT0AndT1() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t0 + 1);
        assertLe(block.timestamp, taken.t1);

        vm.prank(buyer);
        vm.expectRevert(ErrorInvalidOfferStateForQuit.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);
    }

    function testSellQuitRevertsWhenTakenBetweenT0AndT1() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);
        vm.roll(block.number + 1);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t0 + 1);
        assertLe(block.timestamp, taken.t1);

        vm.prank(buyer);
        vm.expectRevert(ErrorInvalidOfferStateForQuit.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);
    }

    /// After `t0`, if the offer is still `TAKEN`, the XMR side may `claim` without `ready` (forced completion window).
    function testBuyClaimWhenTakenAfterT0BeforeT1_WithoutReady() public {
        OfferKeys memory k = _generateOfferKeys();
        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t0 + 1);

        vm.prank(seller);
        exchange.claim(offer_id, k.xmrPrivateSpendKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.CLAIMED));
        assertEq(exchange.liability(), 0);
        assertEq(buyer.balance, buyerBefore - TRADE_AMOUNT);
        assertEq(seller.balance, sellerBefore + TRADE_AMOUNT);
        Utils.checkLiability(address(exchange));
    }

    function testSellClaimWhenTakenAfterT0BeforeT1_WithoutReady() public {
        OfferKeys memory k = _generateOfferKeys();
        uint256 buyerBefore = buyer.balance;
        uint256 sellerBefore = seller.balance;

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);
        vm.roll(block.number + 1);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t0 + 1);

        vm.prank(seller);
        exchange.claim(offer_id, k.xmrPrivateSpendKey);

        assertEq(uint256(_offerSnapshot(offer_id).state), uint256(OfferState.CLAIMED));
        assertEq(exchange.liability(), 0);
        assertEq(buyer.balance, buyerBefore - TRADE_AMOUNT);
        assertEq(seller.balance, sellerBefore + TRADE_AMOUNT);
        Utils.checkLiability(address(exchange));
    }

    function testClaimRevertsAfterT1WhenReady() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(buyer);
        exchange.ready(offer_id);

        XMRP2P.Offer memory o = _offerSnapshot(offer_id);
        vm.warp(o.t1 + 1);

        vm.prank(seller);
        vm.expectRevert(ErrorClaimUnavailable.selector);
        exchange.claim(offer_id, k.xmrPrivateSpendKey);
    }

    function testClaimRevertsAfterT1WhenStillTaken() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        XMRP2P.Offer memory taken = _offerSnapshot(offer_id);
        vm.warp(taken.t1 + 1);

        vm.prank(seller);
        vm.expectRevert(ErrorClaimUnavailable.selector);
        exchange.claim(offer_id, k.xmrPrivateSpendKey);
    }

    function testQuitRevertsOnWrongEvmPrivateSpendKey() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(buyer);
        vm.expectRevert(ErrorBuyOfferInvalidEVMPrivateSpendKey.selector);
        exchange.quit(offer_id, k.xmrPrivateSpendKey, k.evmPrivateViewKey);
    }

    function testQuitRevertsOnWrongEvmPrivateViewKey() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(buyer);
        vm.expectRevert(ErrorInvalidEVMPrivateViewKey.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.xmrPrivateViewKey);
    }

    function testBuyQuitRevertsWhenCallerIsCounterparty() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(seller);
        vm.expectRevert(ErrorNonMember.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);
    }

    function testSellQuitRevertsWhenCallerIsMaker() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);
        vm.roll(block.number + 1);

        vm.prank(seller);
        vm.expectRevert(ErrorNonMember.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);
    }

    function testSellQuitRevertsInSameBlockAsTake() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(seller);
        exchange.offer{value: REQUIRED_DEPOSIT}(
            OfferType.SELL, TRADE_PRICE, address(0), k.xmrPublicSpendKey, k.xmrPrivateViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(buyer);
        exchange.take{value: TRADE_AMOUNT}(offer_id, k.evmPublicSpendKey, k.evmPublicViewKey);

        vm.prank(buyer);
        vm.expectRevert(ErrorSellOfferCannotQuitInTakenBlock.selector);
        exchange.quit(offer_id, k.evmPrivateSpendKey, k.evmPrivateViewKey);
    }

    function testClaimRevertsOnWrongXmrPrivateSpendKey() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );
        uint256 offer_id = exchange.nextOfferId() - 1;

        vm.prank(seller);
        exchange.take{value: REQUIRED_DEPOSIT}(offer_id, k.xmrPublicSpendKey, k.xmrPrivateViewKey);

        vm.prank(buyer);
        exchange.ready(offer_id);

        vm.prank(seller);
        vm.expectRevert(ErrorInvalidPrivateSpendKey.selector);
        exchange.claim(offer_id, k.evmPrivateSpendKey);
    }

    function testSetParametersRevertsUnlessOwner() public {
        XMRP2P.Parameters memory nextParams = XMRP2P.Parameters({
            MINIMUM_OFFER: 0.00002 ether,
            MAXIMUM_OFFER: 11 ether,
            DEPOSIT_RATIO: DEPOSIT_RATIO,
            MAXIMUM_OFFER_BOOK_SIZE: 100,
            T0_DELAY: 48 hours,
            T1_DELAY: 48 hours
        });

        vm.prank(buyer);
        vm.expectRevert(Ownable.Unauthorized.selector);
        exchange.setParameters(nextParams);

        vm.prank(admin);
        exchange.setParameters(nextParams);
        (,,,, uint256 t0_delay,) = exchange.parameters();
        assertEq(t0_delay, 48 hours);
    }

    function testRecoverSendsSurplusToOwner() public {
        OfferKeys memory k = _generateOfferKeys();

        vm.prank(buyer);
        exchange.offer{value: TRADE_AMOUNT}(
            OfferType.BUY, TRADE_PRICE, address(0), k.evmPublicSpendKey, k.evmPublicViewKey
        );

        uint256 dust = 0.5 ether;
        vm.deal(address(exchange), address(exchange).balance + dust);
        uint256 adminBefore = admin.balance;

        vm.prank(admin);
        exchange.recover();

        assertEq(admin.balance, adminBefore + dust);
        assertEq(address(exchange).balance, exchange.liability());
    }
}
