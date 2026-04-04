// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";

/// Tests for testing scenarios related to the use of the refund function
contract MoneroSwapUpdateBuyOfferTest is Test {

    uint256 KEY_BASE = 100000000000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);

    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;
 
    function test_RevertWhen_BuyOfferUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to update an non existent buy offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferUnknown.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );
    }

    function test_RevertWhen_UnauthorizedCaller() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 1,      // public spend key
            KEY_BASE + 2      // public view key
        );

        // Attempt to update the offer from ADDR_3
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        vm.expectRevert(ErrorBuyOfferInvalidCallerForUpdate.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );
    }

    // FIXME(hbs)
    function test_RevertWhen_BuyOfferInvalidStateForUpdate() public {
        
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 3,      // public spend key
            KEY_BASE + 4      // public view key
        );

        // Take the offer so it is no longer updatable
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            KEY_BASE + 5,      // publicspendkey
            KEY_BASE + 6      // privateviewkey
        );

        // Attempt to update an buy offer that is not in the OPEN state
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForUpdate.selector,
                OfferState.TAKEN
            )
        );
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );        
    }

    function test_RevertWhen_NewMaxAmountOutsideRange() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1 ether, // MinimumBuyOffer,
            2 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            10 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 7,      // public spend key
            KEY_BASE + 8      // public view key
        );

        //
        // First do checks with a reduced Max Amount
        //

        // Attempt to update the offer with a new max amount that is below the range
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountBelowMinimum.selector,
                1 ether
            )
        );
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            0.5 ether,         // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );

        // Attempt to update the offer with a new max amount that is above the new range
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            0.25 ether, // MinimumBuyOffer,
            0.5 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            10 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountAboveMaximum.selector,
                0.5 ether
            )
        );
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            0.75 ether,        // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );

        //
        // Now perform checks with an increased max amount
        //

        // Attempt to update the offer with a new max amount that is above the new range
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountAboveMaximum.selector,
                0.5 ether
            )
        );
        moneroswap.updateBuyOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );

        // Change the range
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            3 ether, // MinimumBuyOffer,
            4 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            10 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );

        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountBelowMinimum.selector,
                3 ether
            )
        );
        moneroswap.updateBuyOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1_000_000_000_000 // min XMR
        );
    }

    function test_RevertWhen_NoValueAllowedWhenReducingMaxamount() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1,                 // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 17,     // public spend key
            KEY_BASE + 18     // public view key
        );

        // Attempt to update the offer with a value when reducing maxamount
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNoValueAllowedWhenReducingMaxamount.selector);
        moneroswap.updateBuyOffer{value: 1 wei}(
            1,                 // offer id
            address(0),        // counterparty
            0.5 ether,         // max amount
            1,                 // price
            1_000_000_000_000 // min XMR
        );
    }
    function testUpdateBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 3 ether);
        vm.prank(ADDR_1);
        uint256 evmDeposit = 2 ether;
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(1),        // counterparty
            1,                 // fixed price
            1_000_000_000_000, // min XMR
            KEY_BASE + 19,     // public spend key
            KEY_BASE + 20     // public view key
        );

        Offer memory offer = moneroswap.getBuyOffer(1);

        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.BUY);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, evmDeposit);
        assertEq(offer.price, 1);
        assertEq(offer.minxmr, 1_000_000_000_000);
        assertEq(offer.deposit, evmDeposit);
        assertEq(offer.funded, false);        
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPublicSpendKey, KEY_BASE + 19);
        assertEq(offer.evmPublicViewKey, KEY_BASE + 20);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.xmrPublicSpendKey, 0);
        assertEq(offer.xmrPrivateViewKey, 0);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);
        assertEq(offer.index, 0);

        assertEq(evmDeposit, moneroswap.getLiability());
        uint256 liabilityBefore = moneroswap.getLiability();
        uint256 balanceBefore = ADDR_1.balance;

        // Update the offer by reducing its maxamount from 2 to 1 ether
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.BUY,
            OfferState.OPEN
        );
        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(4),        // counterparty
            1 ether,           // max amount
            2,                 // price
            1_000_000_000_001 // min XMR
        );
        
        offer = moneroswap.getBuyOffer(1);
        assertEq(address(4), offer.counterparty);
        assertEq(ADDR_1, offer.manager);
        assertEq(offer.price, 2);
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.minxmr, 1_000_000_000_001);
        assertEq(offer.deposit, evmDeposit - 1 ether);
        // We expect the account's balance to receive the delta from the previous maxamount
        // and the liability to decrease by the same amount
        assertEq(balanceBefore + (evmDeposit - 1 ether), ADDR_1.balance);
        assertEq(liabilityBefore - (evmDeposit - 1 ether), moneroswap.getLiability());

        liabilityBefore = moneroswap.getLiability();
        // Now update the offer with a non 0 value
        vm.prank(ADDR_1);
        moneroswap.updateBuyOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            3,                 // price
            1_000_000_000_002 // min XMR
        );

        offer = moneroswap.getBuyOffer(1);
        assertEq(address(0), offer.counterparty);
        assertEq(ADDR_1, offer.manager);
        assertEq(offer.price, 3);
        assertEq(offer.maxamount, 2 ether);
        assertEq(offer.minxmr, 1_000_000_000_002);
        assertEq(offer.deposit, evmDeposit);
        assertEq(liabilityBefore + 1 ether, moneroswap.getLiability());
    }
}
