// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {DummyPriceOracle} from "./DummyPriceOracle.t.sol";

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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 1,      // public spend key
            KEY_BASE + 2,      // public view key
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 3,      // public spend key
            KEY_BASE + 4,      // public view key
            0                  // msg pub key
        );

        // Take the offer so it is no longer updatable
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            KEY_BASE + 5,      // publicspendkey
            KEY_BASE + 6,      // privateviewkey
            0                  // msgpubkey
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 7,      // public spend key
            KEY_BASE + 8,      // public view key
            0                  // msg pub key
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
            0.5 ether,           // max amount
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0.75 ether,           // max amount
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
        );
    }

    function test_RevertWhen_NoPriceAndNoOracle() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 11,     // public spend key
            KEY_BASE + 12,     // public view key
            0                  // msg pub key
        );

        // Attempt to update the offer with no price and no oracle
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNoPriceOracleDefined.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            0,                 // price
            1,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
        );
    }

    function test_RevertWhen_PriceAndOracleParams() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 13,     // public spend key
            KEY_BASE + 14,     // public view key
            0                  // msg pub key
        );

        // Attempt to update the offer with a price and oracle params
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNoPriceRatioWithFixedPrice.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            1,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
        );

                vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNoPriceOffsetWithFixedPrice.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            1 ether,           // price
            0,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
        );
    }

    function test_RevertWhen_MissingMaxPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 15,     // public spend key
            KEY_BASE + 16,     // public view key
            0                  // msg pub key
        );

        // Attempt to update the offer with a missing max price when using an oracle
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferMandatoryMaxpriceWithOraclePrice.selector);
        moneroswap.updateBuyOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            0,                 // price
            1,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            0,                 // max price
            0                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 17,     // public spend key
            KEY_BASE + 18,     // public view key
            0                  // msg pub key
        );

        // Attempt to update the offer with a missing max price when using an oracle
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferNoValueAllowedWhenReducingMaxamount.selector);
        moneroswap.updateBuyOffer{value: 1 wei}(
            1,                 // offer id
            address(0),        // counterparty
            0.5 ether,           // max amount
            0,                 // price
            1,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0                  // msg pub key
        );
    }

    function test_RevertWhen_UsedPublicMessageKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 3 ether);
        vm.prank(ADDR_1);
        uint256 evmDeposit = 2 ether;
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(0),        // counterparty
            1,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // public spend key
            2,                 // public view key
            3                  // msg pub key
        );

        // Attempt to update offer with pub message key 1 (used public spend key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );

        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            1                 // msg pub key
        );

        // Attempt to update offer with pub message key 2 (used public view key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );

        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            2                 // msg pub key
        );

        //
        // Create another buy offer using message key 6
        //

        vm.deal(ADDR_1, 3 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(1),        // counterparty
            1,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            4,                 // public spend key
            5,                 // public view key
            6                  // msg pub key
        );

        // Attempt to update offer with pub message key 1 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );

        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            6                  // msg pub key
        ); 

        //
        // Now attempt to update with the same key as the one we used initially, this is ok
        //
        vm.prank(ADDR_1);
        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            3                  // msg pub key
        );

        //
        // Now update with a new key
        //
        vm.prank(ADDR_1);
        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            7                  // msg pub key
        );

        //
        // Now check that the original key cannot be used again
        //
        // Attempt to update offer with pub message key 1 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );

        moneroswap.updateBuyOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            evmDeposit,        // max amount
            1,                 // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            3                  // msg pub key
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 19,     // public spend key
            KEY_BASE + 20,     // public view key
            9                  // msg pub key
        );

        Offer memory offer = moneroswap.getBuyOffer(1);

        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.BUY);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, evmDeposit);
        assertEq(offer.price, 1);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minxmr, 1_000_000_000_000);
        assertEq(offer.maxprice, 1); // Maxprice is set to the fixed price
        assertEq(offer.minprice, 0);
        assertEq(offer.deposit, evmDeposit);
        assertEq(offer.funded, false);        
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPublicSpendKey, KEY_BASE + 19);
        assertEq(offer.evmPublicViewKey, KEY_BASE + 20);
        assertEq(offer.evmPublicMsgKey, 9);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.xmrPublicSpendKey, 0);
        assertEq(offer.xmrPrivateViewKey, 0);
        assertEq(offer.xmrPublicMsgKey, 0);
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
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_001, // min XMR
            1 ether,           // max price
            42                 // msg pub key
        );
        
        offer = moneroswap.getBuyOffer(1);
        assertEq(address(4), offer.counterparty);
        assertEq(ADDR_1, offer.manager);
        assertEq(offer.price, 2);
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.maxprice, 2);
        assertEq(offer.minxmr, 1_000_000_000_001);
        assertEq(offer.minprice, 0);
        assertEq(offer.deposit, evmDeposit - 1 ether);
        assertEq(offer.evmPublicMsgKey, 42);
        
        // We expect the account's balance to receive the delta from the previous maxamount
        // and the liability to decrease by the same amount
        assertEq(balanceBefore + (evmDeposit - 1 ether), ADDR_1.balance);
        assertEq(liabilityBefore - (evmDeposit - 1 ether), moneroswap.getLiability());

        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        liabilityBefore = moneroswap.getLiability();
        // Now update the offer with a non 0 value and change the price to a dynamic one
        vm.prank(ADDR_1);
        moneroswap.updateBuyOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // max amount
            0,                 // price
            1,                 // oracle ratio
            2,                 // oracle offset
            1_000_000_000_002, // min XMR
            100,               // max price
            0                  // msg pub key
        );

        offer = moneroswap.getBuyOffer(1);
        assertEq(address(0), offer.counterparty);
        assertEq(ADDR_1, offer.manager);
        assertEq(offer.price, 0);
        assertEq(offer.oracleRatio, 1);
        assertEq(offer.oracleOffset, 2);
        assertEq(offer.maxamount, 2 ether);
        assertEq(offer.maxprice, 100);
        assertEq(offer.minxmr, 1_000_000_000_002);
        assertEq(offer.minprice, 0);
        assertEq(offer.deposit, evmDeposit);
        assertEq(offer.evmPublicMsgKey, 0);

        assertEq(liabilityBefore + 1 ether, moneroswap.getLiability());
    }
}