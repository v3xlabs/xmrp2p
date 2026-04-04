// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";
import {EIP7702NoPaymentDelegate} from "./EIP7702NoPaymentDelegate.t.sol";

/// Tests for testing scenarios related to the use of the refund function
contract MoneroSwapRefundTest is Test {

    address ADDR_1;
    uint256 PK_1;
    address ADDR_2;
    uint256 PK_2;

    function setUp() public {
        // Generate deterministic keys

        (ADDR_1, PK_1) = makeAddrAndKey("user-1");
        (ADDR_2, PK_2) = makeAddrAndKey("user-2");
    }

    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;


    function test_RevertWhen_InvalidOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to refund an invalid offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorInvalidOffer.selector);
        moneroswap.refund(1, 0, 0);
    }

    function test_RevertWhen_BuyOfferInvalidStateRefunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );
        vm.prank(ADDR_1);
        moneroswap.ready(1);
        Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);
        vm.prank(ADDR_1);
        moneroswap.refund(
            1,
            evmPrivateSpendKey,
            evmPrivateViewKey
        );

        // Attempt to refund the offer again
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForRefund.selector,
                OfferState.REFUNDED
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_BuyOfferInvalidStateClaimed() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Claim the offer
        vm.prank(ADDR_2);
        moneroswap.claim(1, xmrPrivateSpendKey);
        
        // Attempt to refund the offer
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForRefund.selector,
                OfferState.CLAIMED
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_BuyOfferTakenAndBetweenT0AndT1() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offer = moneroswap.getBuyOffer(1);
        
        vm.warp(offer.t0 + 1); // Position time between T0 and T1 so refund cannot be called

        // Attempt to refund the offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferBetweenT0AndT1.selector);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }
    
    function test_RevertWhen_BuyOfferReadyAndBeforeT1() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Ready the offer
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        Offer memory offer = moneroswap.getBuyOffer(1);
        
        vm.warp(offer.t1 - 1); // Position time before T1 so refund cannot be called

        // Attempt to refund the offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNotAfterT1.selector);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_BuyOfferNotOwner() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offer = moneroswap.getBuyOffer(1);
        // Advance past t1 so the offer can be refunded
        vm.warp(offer.t1 + 1);

        // Attempt to refund the offer from an address not owner
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorBuyOfferNotOwner.selector);
        moneroswap.refund(1, xmrPrivateSpendKey, xmrPrivateViewKey);
    }

    function test_RevertWhen_BuyOfferInvalidEVMPrivateSpendKey() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        Offer memory offer = moneroswap.getBuyOffer(1);
        // Advance past t1 so the offer can be refunded
        vm.warp(offer.t1 + 1);

        // Attempt to refund the offer with an invalid private spend key
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferInvalidEVMPrivateSpendKey.selector);
        moneroswap.refund(1, evmPrivateSpendKey + 1, evmPrivateViewKey);
    }
    
    function test_RevertWhen_BuyOfferInvalidEVMPrivateViewKey() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        // Attempt to refund the offer with an invalid private view key
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferInvalidEVMPrivateViewKey.selector);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey + 1);
    }
    
    function test_RevertWhen_SellOfferInvalidStateRefunded() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Advance the block number as we cannot call take and refund in the same block
        vm.roll(block.number + 1);
        // Refund the offer
        vm.prank(ADDR_2);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        // Attempt to refund it again
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferInvalidStateForRefund.selector,
                OfferState.REFUNDED
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_SellOfferInvalidStateClaimed() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Ready the offer
        vm.prank(ADDR_2);
        moneroswap.ready(1);

        // Claim the offer
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey);

        // Attempt to refund
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferInvalidStateForRefund.selector,
                OfferState.CLAIMED
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_SellOfferTakenAndBetweenT0AndT1() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Advance block number since we cannot call take and refund within the same block
        vm.roll(block.number + 1);

        Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t0 + 1);

        // Attempt to refund
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferBetweenT0AndT1.selector
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_SellOfferReadyAndBeforeT1() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Ready the offer
        vm.prank(ADDR_2);
        moneroswap.ready(1);

        Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 - 1);

        // Attempt to refund
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNotAfterT1.selector
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_SellOfferNotCounterparty() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Advance block number since we cannot call take and refund in the same block
        vm.roll(block.number + 1);

        // Attempt to refund it again
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNotCounterparty.selector
            )
        );
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);
    }

    function test_RevertWhen_SellOfferInvalidEVMPrivateSpendKey() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Advance block number since we cannot call take and refund in the same block
        vm.roll(block.number + 1);

        // Attempt to refund the offer with an invalid private spend key
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorSellOfferInvalidEVMPrivateSpendKey.selector);
        moneroswap.refund(1, evmPrivateSpendKey + 1, evmPrivateViewKey);        
    }

    function test_RevertWhen_SellOfferInvalidEVMPrivateViewKey() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Advance block number since we cannot call take and revert within the same block
        vm.roll(block.number + 1);

        // Revert at t1 + 1
        Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 + 1);

        // Attempt to refund the offer with an invalid private view key
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorSellOfferInvalidEVMPrivateViewKey.selector);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey + 1);        

    }

    function testRefundSellOffer_RevertWhen_TakeAndRefundCalledWithinSameBlock() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorSellOfferCannotRefundInTakenBlock.selector);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);        
    }

    // The following 4 tests only cover the refund of taken offers as the implementation knowledge
    // tells us that this is no different than doing the same on a ready offer and that refunding before T0 or after T1 is the same.
    // To be 100% sure we should really test all cases...
    function testRefundBuyOffer() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Extract takerDeposit
        Offer memory offer = moneroswap.getBuyOffer(1);
        uint256 takerDeposit = offer.takerDeposit;

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        assertEq(0, offer.takerDeposit);
        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore + takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit - takerDeposit, moneroswap.getLiability());
    }

    function testRefundBuyOfferWithFundingRequest() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // create a FundingRequest and get it funded
        vm.deal(ADDR_2, 0.1 ether);
        vm.prank(ADDR_2);
        moneroswap.createFundingRequest(1 ether, 0.1 ether);
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_2);
        assertEq(0, moneroswap.getFundingRequest(ADDR_2).usedby);
        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);        
        moneroswap.takeBuyOffer{value: 0}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );
        assertEq(1, moneroswap.getFundingRequest(ADDR_2).usedby);

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        Offer memory offer = moneroswap.getBuyOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit, moneroswap.getLiability());

        // Check that the funding request is no longer used
        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_2);
        assertEq(0, freq.usedby);
    }

    function testRefundSellOffer() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Advance block number since we cannot call take and refund within the same block
        vm.roll(block.number + 1);

        // Extract deposit
        Offer memory offer = moneroswap.getSellOffer(1);
        uint256 deposit = offer.deposit;

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.SELL, OfferState.REFUNDED);        
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        assertEq(0, offer.deposit);
        assertEq(addr1BalanceBefore + deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore + offer.takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - deposit - offer.takerDeposit, moneroswap.getLiability());
    }

    function testRefundSellOfferWithFundingRequest() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create and fund a FundingRequest
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0.1 ether);
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);
        assertEq(0, moneroswap.getFundingRequest(ADDR_1).usedby);
                
        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        assertEq(1, moneroswap.getFundingRequest(ADDR_1).usedby);

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Advance block number since we cannot call take and refund within the same block
        vm.roll(block.number + 1);

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.SELL, OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        Offer memory offer = moneroswap.getSellOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore + offer.takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit - offer.takerDeposit, moneroswap.getLiability());
        assertEq(0, moneroswap.getFundingRequest(ADDR_1).usedby);
    }

    function testRefundBuyOfferWithSellerEIP7702Delegation() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Extract takerDeposit
        Offer memory offer = moneroswap.getBuyOffer(1);
        uint256 takerDeposit = offer.takerDeposit;

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_2);

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        // Refund did not send amount to taker since its EIP7702 delegation prohibits it, so taker deposit and balance of ADDR_2 did not change
        assertEq(takerDeposit, offer.takerDeposit);
        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit, moneroswap.getLiability());

        vm.signAndAttachDelegation(address(0), PK_2);
    }

    function testRefundBuyOffer__RevertWhen_BuyerEIP7702Delegation() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

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
            evmPublicSpendKey, // public spend key
            evmPublicViewKey,  // public view key
            0                 // msg pub key
        );

        // Take the offer, ready it and refund it twice
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            xmrPublicSpendKey, // publicspendkey
            xmrPrivateViewKey, // privateviewkey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Attach a Delegation on buyer
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_1);

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferUnableToRefund.selector);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        vm.signAndAttachDelegation(address(0), PK_1);
    }

    function testRefundSellOfferWithSellerEIP7702Delegation() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Advance block number since we cannot call take and refund within the same block
        vm.roll(block.number + 1);

        // Extract deposit
        Offer memory offer = moneroswap.getSellOffer(1);
        uint256 deposit = offer.deposit;

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_1);

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.SELL, OfferState.REFUNDED);        
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == OfferState.REFUNDED);

        // Balance and deposit did not change since the latter could not be sent back
        assertEq(deposit, offer.deposit);
        assertEq(addr1BalanceBefore, ADDR_1.balance);
        assertEq(addr2BalanceBefore + offer.takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.takerDeposit, moneroswap.getLiability());

        vm.signAndAttachDelegation(address(0), PK_1);
    }

    function testRefundSellOffer_RevertWhen_BuyerEIP7702Delegation() public {
        MoneroSwap  moneroswap = new MoneroSwap(msg.sender);

        // Generate keys
        (
            uint256 evmPrivateViewKey,
            uint256 evmPrivateSpendKey,
            uint256 evmPublicViewKey,
            uint256 evmPublicSpendKey,
            uint256 xmrPrivateViewKey,
            uint256 xmrPrivateSpendKey,
            uint256 xmrPublicViewKey,
            uint256 xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey, // public spend key
            xmrPrivateViewKey,  // private view key
            0                 // msg pub key
        );

        // Take the offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1,
            1_000_000_000_000, // minxmr
            1 ether,           // maxprice
            evmPublicSpendKey, // publicspendkey
            evmPublicViewKey, // publicViewKey
            0                  // msgpubkey
        );

        uint256 addr1BalanceBefore = ADDR_1.balance;
        uint256 addr2BalanceBefore = ADDR_2.balance;
        uint256 liabilityBefore = moneroswap.getLiability();

        // Advance block number since we cannot call take and refund within the same block
        vm.roll(block.number + 1);

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_2);

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectRevert(ErrorSellOfferUnableToRefund.selector);        
        emit MoneroSwap.OfferEvent(1, OfferType.SELL, OfferState.REFUNDED);        
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        vm.signAndAttachDelegation(address(0), PK_2);
    }

}