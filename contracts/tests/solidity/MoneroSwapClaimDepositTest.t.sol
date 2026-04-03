// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";
import {Utils} from "./Utils.t.sol";
import {EIP7702NoPaymentDelegate} from "./EIP7702NoPaymentDelegate.t.sol";

contract MoneroSwapClaimDepositTest is Test {

    uint256 KEY_BASE = 10000;

    address ADDR_1;
    uint256 PK_1;
    address ADDR_2;
    uint256 PK_2;
    address ADDR_3;
    uint256 PK_3;

    function setUp() public {
        // Generate deterministic keys

        (ADDR_1, PK_1) = makeAddrAndKey("user-1");
        (ADDR_2, PK_2) = makeAddrAndKey("user-2");
        (ADDR_3, PK_3) = makeAddrAndKey("user-3");
    }

    function test_RevertWhen_FundedBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Create a buy offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            KEY_BASE + 1,
            KEY_BASE + 2,
            0                  // msg pub key        
        );

        // Take the offer
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer(1, 1_000_000_000_000, 1 ether, 11, 12, 0);

        // Advance time to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);

        // Attempt to claim deposit
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorBuyOfferCannotClaimDepositOfFundedOffer.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_FundedSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1_000_000_000_000, // max XMR
            KEY_BASE + 3,
            KEY_BASE + 4,
            0                  // msg pub key        
        );

        // Take the offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.takeSellOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, 11, 12, 0);

        // Advance time to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 + 1);

        // Attempt to claim deposit
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorSellOfferCannotClaimDepositOfFundedOffer.selector);
        moneroswap.claimDeposit(1);
    }   

    function test_RevertWhen_BuyOfferNotAfterT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            KEY_BASE + 5,
            KEY_BASE + 6,
            0                  // msg pub key        
        );

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, 11, 12, 0);

        // Attempt to claim deposit
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorBuyOfferNotAfterT1OrRefunded.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_SellOfferNotAfterT1() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1_000_000_000_000, // max XMR
            KEY_BASE + 7,
            KEY_BASE + 8,
            0                  // msg pub key        
        );

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeSellOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, 11, 12, 0);

        // Attempt to claim deposit
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorSellOfferNotAfterT1OrRefunded.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_BuyOfferInvalidState() public {
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
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key        
        );

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, xmrPublicSpendKey, xmrPrivateViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_3);
        moneroswap.ready(1);

        // Claim the offer
        vm.prank(ADDR_1);
        moneroswap.claim(1, xmrPrivateSpendKey);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);
                
        // Attempt to claim deposit
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorBuyOfferInvalidStateForClaimDeposit.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_SellOfferInvalidState() public {
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

        // Create a sell offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            0                  // msg pub key        
        );

        uint256 xmrPrivateSK = xmrPrivateSpendKey;

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeSellOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, evmPublicSpendKey, evmPublicViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Claim the offer
        vm.prank(ADDR_3);
        moneroswap.claim(1, xmrPrivateSK);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 + 1);
                
        // Attempt to claim deposit
        vm.prank(ADDR_3);
        vm.expectRevert(MoneroSwap.ErrorSellOfferInvalidStateForClaimDeposit.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_NotTaker() public {
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
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key        
        );

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, xmrPublicSpendKey, xmrPrivateViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_3);
        moneroswap.ready(1);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);
                
        // Attempt to claim deposit
        vm.prank(ADDR_2);
        vm.expectRevert(MoneroSwap.ErrorBuyOfferNotTaker.selector);
        moneroswap.claimDeposit(1);
    }

    function test_RevertWhen_NotOwner() public {
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

        // Create a sell offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            0                  // msg pub key        
        );

        uint256 xmrPrivateSK = xmrPrivateSpendKey;

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeSellOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, evmPublicSpendKey, evmPublicViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 + 1);
                
        // Attempt to claim deposit
        vm.prank(ADDR_2);
        vm.expectRevert(MoneroSwap.ErrorSellOfferNotOwner.selector);
        moneroswap.claimDeposit(1);
    }

    function testClaimDepositBuyOffer() public {
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
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key        
        );

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeBuyOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, xmrPublicSpendKey, xmrPrivateViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_3);
        moneroswap.ready(1);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        vm.warp(offer.t1 + 1);
                
        uint256 liability = moneroswap.getLiability();
        uint256 balance = address(ADDR_1).balance;
        
        // Attempt to claim deposit
        vm.prank(ADDR_1);
        moneroswap.claimDeposit(1);

        assertEq(balance + offer.takerDeposit, address(ADDR_1).balance);
        assertEq(liability - offer.takerDeposit, moneroswap.getLiability());

        offer = moneroswap.getBuyOffer(1);
        assertEq(0, offer.takerDeposit);
    }

    function testClaimDepositSellOffer() public {
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

        // Create a sell offer
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1_000_000_000_000, // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            0                  // msg pub key        
        );

        uint256 xmrPrivateSK = xmrPrivateSpendKey;

        // Generate keys
        (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        ) = Utils.generateOfferKeys(vm);

        // Take the offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.takeSellOffer{value: 1 ether}(1, 1_000_000_000_000, 1 ether, evmPublicSpendKey, evmPublicViewKey, 0);

        // Ready the offer
        vm.prank(ADDR_1);
        moneroswap.ready(1);

        // Advance to t1 + 1
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        vm.warp(offer.t1 + 1);
                
        uint256 liability = moneroswap.getLiability();
        uint256 balance = address(ADDR_3).balance;

        // Attempt to claim deposit
        vm.prank(ADDR_3);
        moneroswap.claimDeposit(1);

        assertEq(balance + offer.deposit, address(ADDR_3).balance);
        assertEq(liability - offer.deposit, moneroswap.getLiability());

        offer = moneroswap.getSellOffer(1);
        assertEq(0, offer.deposit);
    }

    function testClaimDepositSellOfferWhenSellerEIP7702DelegationAtRefund() public {
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

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
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
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        uint256 deposit = offer.deposit;

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_1);

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.SELL, MoneroSwap.OfferState.REFUNDED);        
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);

        // Balance and deposit did not change since the latter could not be sent back
        assertEq(deposit, offer.deposit);
        assertEq(addr1BalanceBefore, ADDR_1.balance);
        assertEq(addr2BalanceBefore + offer.takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.takerDeposit, moneroswap.getLiability());

        liabilityBefore = moneroswap.getLiability();

        // Remove EIP7702 delegation
        vm.signAndAttachDelegation(address(0), PK_1);

        // Call claimDeposit
        vm.prank(ADDR_1);
        moneroswap.claimDeposit(1);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);
        // deposit is now sent back
        assertEq(deposit, ADDR_2.balance);
        assertEq(0, offer.deposit);
        assertEq(liabilityBefore - deposit, moneroswap.getLiability());
    }
    
    function testClaimDepositSellOfferAfterRefund() public {
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

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
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
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        uint256 deposit = offer.deposit;

        // Refund the offer
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.SELL, MoneroSwap.OfferState.REFUNDED);        
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);

        assertEq(0, offer.deposit);
        assertEq(addr1BalanceBefore + deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore + offer.takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.takerDeposit - deposit, moneroswap.getLiability());

        liabilityBefore = moneroswap.getLiability();
        addr1BalanceBefore = ADDR_1.balance;
        addr2BalanceBefore = ADDR_2.balance;

        // Call claimDeposit
        vm.prank(ADDR_1);
        moneroswap.claimDeposit(1);

        offer = moneroswap.getSellOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);
        // Balances didn't change
        assertEq(addr1BalanceBefore, ADDR_1.balance);
        assertEq(addr2BalanceBefore, ADDR_2.balance);
        assertEq(0, offer.deposit);
        assertEq(liabilityBefore, moneroswap.getLiability());        
    }

    function testClaimDepositBuyOfferAfterRefund() public {
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
            address(0),        // manager
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
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        uint256 takerDeposit = offer.takerDeposit;

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.BUY, MoneroSwap.OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);

        assertEq(0, offer.takerDeposit);
        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore + takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit - takerDeposit, moneroswap.getLiability());

        liabilityBefore = moneroswap.getLiability();
        addr1BalanceBefore = ADDR_1.balance;
        addr2BalanceBefore = ADDR_2.balance;

        // Call claimDeposit
        vm.prank(ADDR_2);
        moneroswap.claimDeposit(1);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);
        // Balance didn't change
        assertEq(addr1BalanceBefore, ADDR_1.balance);
        assertEq(addr2BalanceBefore, ADDR_2.balance);
        assertEq(0, offer.takerDeposit);
    }
    
    function testClaimDepositBuyOfferWhenSellerEIP7702DelegationAtRefund() public {
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
            address(0),        // manager
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
        MoneroSwap.Offer memory offer = moneroswap.getBuyOffer(1);
        uint256 takerDeposit = offer.takerDeposit;

        // Attach a Delegation on seller
        vm.signAndAttachDelegation(address(new EIP7702NoPaymentDelegate()), PK_2);

        // Refund the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.BUY, MoneroSwap.OfferState.REFUNDED);
        moneroswap.refund(1, evmPrivateSpendKey, evmPrivateViewKey);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);

        // Refund did not send amount to taker since its EIP7702 delegation prohibits it, so taker deposit and balance of ADDR_2 did not change
        assertEq(takerDeposit, offer.takerDeposit);
        assertEq(addr1BalanceBefore + offer.deposit, ADDR_1.balance);
        assertEq(addr2BalanceBefore, ADDR_2.balance);
        assertEq(liabilityBefore - offer.deposit, moneroswap.getLiability());

        vm.signAndAttachDelegation(address(0), PK_2);

        addr1BalanceBefore = ADDR_1.balance;
        addr2BalanceBefore = ADDR_2.balance;
        liabilityBefore = moneroswap.getLiability();

        // Now claim the deposit
        vm.prank(ADDR_2);
        moneroswap.claimDeposit(1);

        offer = moneroswap.getBuyOffer(1);
        assert(offer.state == MoneroSwap.OfferState.REFUNDED);
        // Balance didn't change
        assertEq(addr1BalanceBefore, ADDR_1.balance);
        assertEq(addr2BalanceBefore + takerDeposit, ADDR_2.balance);
        assertEq(liabilityBefore - takerDeposit, moneroswap.getLiability());
        assertEq(0, moneroswap.getLiability());
        assertEq(0, offer.takerDeposit);        
    }    
}