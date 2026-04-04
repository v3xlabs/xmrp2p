// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {DummyPriceOracle} from "./DummyPriceOracle.t.sol";
import {Ed25519} from "../../src/Ed25519.sol";

import {Utils} from "./Utils.t.sol";

/// Tests for testing scenarios related to the use of the refund function
contract MoneroSwapUpdateSellOfferTest is Test {

    uint256 KEY_BASE = 10000000000000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);

    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;
    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;

    function test_RevertWhen_SellOfferUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to update an non existent sell offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorSellOfferUnknown.selector);
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            0,                 // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_UnauthorizedCaller() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1,                // max XMR
            KEY_BASE + 1,
            KEY_BASE + 2,
            0                  // msg pub key
        );

        // Attempt to update the offer from ADDR_3
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        vm.expectRevert(ErrorSellOfferInvalidCallerForUpdate.selector);
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            2_000_000_000_000, // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_InvalidState() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer

        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1_000_000_000_000,                // max XMR
            KEY_BASE + 3,
            KEY_BASE + 4,
            0                  // msg pub key
        );

        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        // Take offer
        moneroswap.takeSellOffer{value: 1 ether}(
            1,                 // offer id
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            KEY_BASE + 5,                 // public spend key
            KEY_BASE + 6,                 // public view key
            3                  // msg pub key
        );

        // Attempt to update the offer from ADDR_3
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferInvalidStateForUpdate.selector,
                OfferState.TAKEN
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            2_000_000_000_000, // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_ImmutableDeposit() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Now create an offer with a funding request
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        uint256 price = 1;
        uint256 minxmr = (fee * Utils.UNITS_PER_XMR)/ price;
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            price,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            minxmr,                 // min XMR
            5,                 // min price
            6,                 // max XMR
            KEY_BASE + 7,                 // public spend key
            KEY_BASE + 8,                 // public view key
            9                  // msg pub key
        );

        // Attempt to update the deposit
        price = 1 ether;
        minxmr = (fee * Utils.UNITS_PER_XMR)/ price;
        vm.deal(ADDR_1, 1 ether);   
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorSellOfferImmutableDeposit.selector);
        moneroswap.updateSellOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            4,                 // min XMR
            5,                 // min price
            6,                 // max XMR
            7                 // msg pub key            
        );
    }  

    function test_RevertWhen_MaxamountOutsideRange() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1,                // max XMR
            KEY_BASE + 11,
            KEY_BASE + 12,
            0                  // msg pub key
        );

        // Change valid range
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            0 ether, // MinimumBuyOffer,
            0 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            10 ether, // MinimumSellOffer,
            100 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );

        // Attempt to update the max amount to a value below the new minimum
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferAmountBelowMinimum.selector,
                10 ether
            )
        );
        moneroswap.updateSellOffer{value: 1 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0,                 // max XMR
            0                  // msg pub key
        );

                // Attempt to update the max amount to a value below the new minimum
        vm.deal(ADDR_1, 100 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferAmountAboveMaximum.selector,
                100 ether
            )
        );
        moneroswap.updateSellOffer{value: 100 ether}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            0,                 // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_NoDefinedOracle() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1_000_000_000_000,                // max XMR
            KEY_BASE + 13,
            KEY_BASE + 14,
            0                  // msg pub key
        );

        // Attempt to update the offer with a dynamic price. This should fail since no Oracle is defined
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);    
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNoPriceOracleDefined.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            0 ether,           // price
            1,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            2_000_000_000_000, // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_FixedPriceAndAmountTooLowForFundingFee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Now create an offer with a funding request
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        uint256 price = 1;
        uint256 minxmr = (fee * Utils.UNITS_PER_XMR)/ price;
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            price,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            minxmr,                 // min XMR
            5,                 // min price
            6,                 // max XMR
            KEY_BASE + 15,                 // public spend key
            KEY_BASE + 16,                 // public view key
            9                  // msg pub key
        );

        // Now attempt to update the sell offer with a minimum price which is too low for the funding fee
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(1),        // counterparty
            price,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            minxmr - 1,                 // min XMR
            5,                 // min price
            6,                 // max XMR
            7                  // msg pub key
        );
    }

    function test_RevertWhen_DynamicPriceAndAmountTooLowForFundingFee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Update the offer with a new minxmr/maxxmr and and oracle price + minprice
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        // Now create an offer with a funding request
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        uint256 minprice = 2;
        uint256 minxmr = (fee * Utils.UNITS_PER_XMR)/ minprice;
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            0,                 // fixed price
            1,                 // oracle ratio
            0,                 // oracle offset
            minxmr,            // min XMR
            minprice,          // min price
            6,                 // max XMR
            KEY_BASE + 17,     // public spend key
            KEY_BASE + 18,     // public view key
            9                  // msg pub key
        );

        // Now attempt to update the sell offer with a minimum XMR amount which is too low for the funding fee with a stable minprice
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(1),        // counterparty
            0,                 // fixed price
            2,                 // oracle ratio
            0,                 // oracle offset
            minxmr - 1,        // min XMR
            0,                 // min price
            6,                 // max XMR
            7                  // msg pub key
        );

                // Now attempt to update the sell offer with a minimum price which is too low for the funding fee
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(1),        // counterparty
            0,                 // fixed price
            2,                 // oracle ratio
            0,                 // oracle offset
            minxmr,            // min XMR
            minprice - 1,      // min price
            6,                 // max XMR
            7                  // msg pub key
        );
    }

    function test_RevertWhen_OracleParametersWhenFixedPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            0,                 // min price
            1_000_000_000_000,                // max XMR
            KEY_BASE + 19,
            KEY_BASE + 20,
            0                  // msg pub key
        );

        // Attempt to update the offer with a fixed price and oracle parameters, this should fail.
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNoPriceRatioWithFixedPrice.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            1,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            0,                 // min price
            2_000_000_000_000, // max XMR
            0                  // msg pub key
        );

        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNoPriceOffsetWithFixedPrice.selector
            )
        );
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            1,                 // oracle offset
            1_000_000_000_000, // min XMR
            0,                 // min price
            2_000_000_000_000, // max XMR
            0                  // msg pub key
        );
    }

    function test_RevertWhen_UsedPublicMessageKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, 3 * xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_001, // max XMR
            1,                 // PublicSpendKey
            2,                 // PrivateViewKey
            3                  // PublicMsgKey
        );

        // Update the offer, reusing the public spend key as the message key
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferUsedMessageKey.selector
            )
        );        
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            1                  // msg pub key
        );

        (uint256 x,uint256 y) = Ed25519.scalarMultBase(2);
        uint256 pubViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x,y));

        // Update the offer, reusing the public view key as the message key
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferUsedMessageKey.selector
            )
        );        
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            pubViewKey         // msg pub key
        ); 

        //
        // Create another sell offer with message key 6, so we can attempt to reuse it
        //
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_001, // max XMR
            4,                 // PublicSpendKey
            5,                 // PrivateViewKey
            6                  // PublicMsgKey
        );

        // Update the offer, reusing the public message key 6 as the message key
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferUsedMessageKey.selector
            )
        );        
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            6                  // msg pub key
        ); 

        //
        // Reusing the same message key is fine
        //
        vm.prank(ADDR_1);
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            3                  // msg pub key
        );

        //
        // Update with a new key
        //
        vm.prank(ADDR_1);
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            7                  // msg pub key
        );

        // Attempt to reuse the original key, this will fail
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferUsedMessageKey.selector
            )
        );        
        moneroswap.updateSellOffer{value: 0}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            1 ether,           // min price
            0,                 // maxxmr - unchanged
            3                  // msg pub key
        );         
    }

    function testUpdateSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 libability = moneroswap.getLiability();

        // Create a sell offer
        uint256 xmrDeposit = 1 ether;
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);        
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(1),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1_000_000_000_001, // max XMR
            KEY_BASE + 21,     // PublicSpendKey
            KEY_BASE + 22,     // PrivateViewKey
            7                  // PublicMsgKey
        );

        assertEq(moneroswap.getLiability(), libability + xmrDeposit);

        // Retrieve the offer just created
        Offer memory offer = moneroswap.getSellOffer(1);

        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.SELL);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, xmrDeposit);
        assertEq(offer.price, 1 ether);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minxmr, 1_000_000_000_000);
        assertEq(offer.maxxmr, 1_000_000_000_001);
        assertEq(offer.maxprice, 0); // Maxprice is not set for sell offers
        assertEq(offer.minprice, 1 ether);
        assertEq(offer.deposit, xmrDeposit);
        assertEq(offer.funded, false);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPublicSpendKey, 0);
        assertEq(offer.evmPublicViewKey, 0);
        assertEq(offer.evmPublicMsgKey, 0);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE + 21);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE + 22);        
        assertEq(offer.xmrPublicMsgKey, 7);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);
        assertEq(offer.index, 0);


        // Update the offer, changing the fixed price and sending non 0 value
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.updateSellOffer{value: 10}(
            1,                 // offer id
            address(3),        // counterparty
            2 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            0,                 // min XMR - unchanged
            3 ether,           // min price
            0,                 // maxxmr - unchanged
            8                  // msg pub key
        );

        // Retrieve the offer just updated
        offer = moneroswap.getSellOffer(1);

        assertEq(moneroswap.getLiability(), libability + xmrDeposit + 10);
        
        // Check that the offer is the one we just updated
        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.SELL);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, 1 ether + 10);
        assertEq(offer.price, 2 ether);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minprice, 2 ether); // minprice is forced to the fixed price
        assertEq(offer.minxmr, 1_000_000_000_000);
        assertEq(offer.maxxmr, 1_000_000_000_001);
        assertEq(offer.counterparty, address(3));

        assertEq(offer.xmrPublicSpendKey, KEY_BASE + 21);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE + 22);        
        assertEq(offer.xmrPublicMsgKey, 8);
        assertEq(offer.xmrPrivateSpendKey, 0);  

        // Update the offer with a new minxmr/maxxmr and and oracle price + minprice
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.updateSellOffer(
            1,                 // offer id
            address(0),        // counterparty
            0 ether,           // price
            1,                 // oracle ratio
            9,                 // oracle offset
            1_000_000_000_005, // min XMR
            42,                 // min price
            2_000_000_000_006, // max XMR
            0                  // msg pub key
        );

        // Retrieve the offer just updated
        offer = moneroswap.getSellOffer(1);

        // Check that the offer is the one we just updated
        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.SELL);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, 1 ether + 10);
        assertEq(offer.price, 0);
        assertEq(offer.oracleRatio, 1);
        assertEq(offer.oracleOffset, 9);
        assertEq(offer.minprice, 42); // minprice is forced to the fixed price
        assertEq(offer.minxmr, 1_000_000_000_005);
        assertEq(offer.maxxmr, 2_000_000_000_006);
        assertEq(offer.counterparty, address(0));
        assertEq(offer.xmrPublicMsgKey, 0);
    }

    function testUpdateSellOfferCoverageRatio() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Set coverage ratio to a random number
        uint256 coverageRatio = (vm.randomUint() % (RATIO_DENOMINATOR / 100)) * 95;

        vm.prank(msg.sender);
        moneroswap.setParameters(
            10 ether, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            0, // MinimumBuyOffer,
            0, // MaximumBuyOffer,
            2, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            2**255, // MaximumSellOffer,
            coverageRatio,
            86400, // T0Delay,
            86400  // T1Delay
        );

        uint256 deposit = 10 + (vm.randomUint() % 1 ether);
        vm.deal(ADDR_1, deposit);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: deposit}(
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE + 23,
            KEY_BASE + 24,
            0);

        // Retrieve offer
        Offer memory offer = moneroswap.getSellOffer(1);

        assertEq((deposit * RATIO_DENOMINATOR) / coverageRatio, offer.maxamount);

        uint256 totalDeposit = deposit;
        // Now update the offer with a random value
        deposit = 10 + (vm.randomUint() % 1 ether);
        totalDeposit += deposit;
        vm.deal(ADDR_1, deposit);
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.SELL,
            OfferState.OPEN
        );
        moneroswap.updateSellOffer{value: deposit}(
            1,                 // offer id
            address(0),        // counterparty
            1 ether,           // price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_005, // min XMR
            42,                 // min price
            2_000_000_000_006, // max XMR
            0                  // msg pub key
        );

        // Retrieve offer
        offer = moneroswap.getSellOffer(1);

        assertEq((totalDeposit * RATIO_DENOMINATOR) / coverageRatio, offer.maxamount);
    }
}