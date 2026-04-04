// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapReadyTest is Test {

    uint256 KEY_BASE = 100000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    uint256 UNITS_PER_XMR = 1_000_000_000_000;
 
    function test_RevertWhen_BuyOfferInvalidState() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 1,                 // public spend key
            KEY_BASE + 2,                 // public view key
            0                  // msg pub key
        );

        // Attempt to ready the offer
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForReady.selector,
                OfferState.OPEN
            )
        );
        moneroswap.ready(1);
    }
    
    function test_RevertWhen_BuyOfferNotOwner() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 3,                 // public spend key
            KEY_BASE + 4,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 5,                 // publicspendkey
            KEY_BASE + 6,                 // privateviewkey
            0                  // msgpubkey
        );

        // Attempt to ready the offer
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorBuyOfferNotOwner.selector);
        moneroswap.ready(1);
    }
    
    function test_RevertWhen_BuyOfferAfterT0() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 7,                 // public spend key
            KEY_BASE + 8,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 9,                 // publicspendkey
            KEY_BASE + 10,                 // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offer = moneroswap.getBuyOffer(1);
        // Advance the time past t0
        vm.warp(offer.t0 + 1);

        // Attempt to ready the offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferAfterT0.selector);
        moneroswap.ready(1);
    }

    function testReadyBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 11,                 // public spend key
            KEY_BASE + 12,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // maxxmr
            1 ether,           // minprice
            KEY_BASE + 13,                 // publicspendkey
            KEY_BASE + 14,                 // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offerBeforeReady = moneroswap.getBuyOffer(1);

        // Attempt to ready the offer
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        Offer memory offerAfterReady = moneroswap.getBuyOffer(1);
        assert(OfferState.TAKEN == offerBeforeReady.state);
        assert(OfferState.READY == offerAfterReady.state);
        assert(offerBeforeReady.lastupdate <= offerAfterReady.lastupdate);
        assert(offerBeforeReady.deposit == offerAfterReady.deposit);
        assert(offerBeforeReady.funded == offerAfterReady.funded);
        assert(offerBeforeReady.owner == offerAfterReady.owner);
        assert(offerBeforeReady.manager == offerAfterReady.manager);
        assert(offerBeforeReady.maxamount == offerAfterReady.maxamount);
        assert(offerBeforeReady.price == offerAfterReady.price);
        assert(offerBeforeReady.oracleRatio == offerAfterReady.oracleRatio);
        assert(offerBeforeReady.oracleOffset == offerAfterReady.oracleOffset);
        assert(offerBeforeReady.minxmr == offerAfterReady.minxmr);
        assert(offerBeforeReady.maxprice == offerAfterReady.maxprice);
        assert(offerBeforeReady.maxxmr == offerAfterReady.maxxmr);
        assert(offerBeforeReady.minprice == offerAfterReady.minprice);
        assert(offerBeforeReady.counterparty == offerAfterReady.counterparty);
        assert(offerBeforeReady.evmPublicSpendKey == offerAfterReady.evmPublicSpendKey);
        assert(offerBeforeReady.evmPublicViewKey == offerAfterReady.evmPublicViewKey);
        assert(offerBeforeReady.evmPublicMsgKey == offerAfterReady.evmPublicMsgKey);
        assert(offerBeforeReady.xmrPublicSpendKey == offerAfterReady.xmrPublicSpendKey);
        assert(offerBeforeReady.xmrPublicMsgKey == offerAfterReady.xmrPublicMsgKey);
        assert(offerBeforeReady.evmPrivateSpendKey == offerAfterReady.evmPrivateSpendKey);
        assert(offerBeforeReady.evmPrivateViewKey == offerAfterReady.evmPrivateViewKey);
        assert(offerBeforeReady.xmrPrivateSpendKey == offerAfterReady.xmrPrivateSpendKey);
        assert(offerBeforeReady.xmrPrivateViewKey == offerAfterReady.xmrPrivateViewKey);
        assert(offerBeforeReady.index == offerAfterReady.index);
        assert(offerBeforeReady.takerDeposit == offerAfterReady.takerDeposit);
        assert(offerBeforeReady.finalprice == offerAfterReady.finalprice);
        assert(offerBeforeReady.finalxmr == offerAfterReady.finalxmr);
        assert(offerBeforeReady.t0 == offerAfterReady.t0);
        assert(offerBeforeReady.t1 == offerAfterReady.t1);
    }

    function test_RevertWhen_SellOfferInvalidState() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_000, // maxxmr
            KEY_BASE + 15,                 // public spend key
            KEY_BASE + 16,                 // public view key
            0                  // msg pub key
        );

        // Attempt to ready the offer
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferInvalidStateForReady.selector,
                OfferState.OPEN
            )
        );
        moneroswap.ready(1);
    }

    function test_RevertWhen_SellOfferNotTaker() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_000, // maxxmr
            KEY_BASE + 17,                 // public spend key
            KEY_BASE + 18,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // minxmr
            1 ether,           // maxprice
            KEY_BASE + 19,                 // publicspendkey
            KEY_BASE + 20,                 // privateviewkey
            0                  // msgpubkey
        );

        // Attempt to ready the offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorSellOfferNotTaker.selector);
        moneroswap.ready(1);
    }

    function test_RevertWhen_SellOfferAfterT0() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_000, // maxxmr
            KEY_BASE + 21,                 // public spend key
            KEY_BASE + 22,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // minxmr
            1 ether,           // maxprice
            KEY_BASE + 23,                 // publicspendkey
            KEY_BASE + 24,                 // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offer = moneroswap.getSellOffer(1);
        // Advance the time past t0
        vm.warp(offer.t0 + 1);

        // Attempt to ready the offer
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorSellOfferAfterT0.selector);
        moneroswap.ready(1);
    }

    function testReadySellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_000, // maxxmr
            KEY_BASE + 25,                 // public spend key
            KEY_BASE + 26,                 // public view key
            0                  // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,                 // offer id
            UNITS_PER_XMR,     // minxmr
            1 ether,           // maxprice
            KEY_BASE + 27,                 // publicspendkey
            KEY_BASE + 28,                 // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offerBeforeReady = moneroswap.getSellOffer(1);

        // Attempt to ready the offer
        vm.prank(ADDR_2);
        moneroswap.ready(1);

        Offer memory offerAfterReady = moneroswap.getSellOffer(1);
        assert(OfferState.TAKEN == offerBeforeReady.state);
        assert(OfferState.READY == offerAfterReady.state);
        assert(offerBeforeReady.lastupdate <= offerAfterReady.lastupdate);
        assert(offerBeforeReady.deposit == offerAfterReady.deposit);
        assert(offerBeforeReady.funded == offerAfterReady.funded);
        assert(offerBeforeReady.owner == offerAfterReady.owner);
        assert(offerBeforeReady.manager == offerAfterReady.manager);
        assert(offerBeforeReady.maxamount == offerAfterReady.maxamount);
        assert(offerBeforeReady.price == offerAfterReady.price);
        assert(offerBeforeReady.oracleRatio == offerAfterReady.oracleRatio);
        assert(offerBeforeReady.oracleOffset == offerAfterReady.oracleOffset);
        assert(offerBeforeReady.minxmr == offerAfterReady.minxmr);
        assert(offerBeforeReady.maxprice == offerAfterReady.maxprice);
        assert(offerBeforeReady.maxxmr == offerAfterReady.maxxmr);
        assert(offerBeforeReady.minprice == offerAfterReady.minprice);
        assert(offerBeforeReady.counterparty == offerAfterReady.counterparty);
        assert(offerBeforeReady.evmPublicSpendKey == offerAfterReady.evmPublicSpendKey);
        assert(offerBeforeReady.evmPublicViewKey == offerAfterReady.evmPublicViewKey);
        assert(offerBeforeReady.evmPublicMsgKey == offerAfterReady.evmPublicMsgKey);
        assert(offerBeforeReady.xmrPublicSpendKey == offerAfterReady.xmrPublicSpendKey);
        assert(offerBeforeReady.xmrPublicMsgKey == offerAfterReady.xmrPublicMsgKey);
        assert(offerBeforeReady.evmPrivateSpendKey == offerAfterReady.evmPrivateSpendKey);
        assert(offerBeforeReady.evmPrivateViewKey == offerAfterReady.evmPrivateViewKey);
        assert(offerBeforeReady.xmrPrivateSpendKey == offerAfterReady.xmrPrivateSpendKey);
        assert(offerBeforeReady.xmrPrivateViewKey == offerAfterReady.xmrPrivateViewKey);
        assert(offerBeforeReady.index == offerAfterReady.index);
        assert(offerBeforeReady.takerDeposit == offerAfterReady.takerDeposit);
        assert(offerBeforeReady.finalprice == offerAfterReady.finalprice);
        assert(offerBeforeReady.finalxmr == offerAfterReady.finalxmr);
        assert(offerBeforeReady.t0 == offerAfterReady.t0);
        assert(offerBeforeReady.t1 == offerAfterReady.t1);

    }

    function test_RevertWhen_InvalidOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to ready an invalid offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorInvalidOffer.selector);
        moneroswap.ready(1);
    }
}