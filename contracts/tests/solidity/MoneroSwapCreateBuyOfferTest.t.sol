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
contract MoneroSwapCreateBuyOfferTest is Test {

    uint256 KEY_BASE = 100000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;

    function test_RevertWhen_ReusedPublicKey() public {
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

        // Create an offer
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);        

        uint256 evmDeposit = 2 ether;

        // We are expecting the same event as the one we are emitting just after the call to expectEmit
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.OPEN);
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key
        );

        // Attempt to create another offer with the same public spend key
        vm.prank(ADDR_1);       
        vm.expectRevert(ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector);
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key
        );
    }

    function test_RevertWhen_BuyOfferMaxBookSizeReached() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        // Set parameters to limit offer book size to 1
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1000 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );

        // Create a first offer
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

        // Create an offer
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);        

        uint256 evmDeposit = 2 ether;

        // We are expecting the same event as the one we are emitting just after the call to expectEmit
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.BUY, OfferState.OPEN);
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey,
            evmPublicViewKey,
            0                  // msg pub key
        );

        // Attempt to create another offer

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

        vm.prank(ADDR_1);       
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferMaximumOfferBookSizeReached.selector,
                1
            )
        );
        moneroswap.createBuyOffer{value: evmDeposit}(
            address(0),        // counterparty
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            evmPublicSpendKey + 1,
            evmPublicViewKey + 1,
            0                  // msg pub key
        );
    }

    function test_RevertWhen_AmountNotInRange() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            10, // MinimumBuyOffer,
            100, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountBelowMinimum.selector,
                10
            )
        );
        moneroswap.createBuyOffer{value: 1}(
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            KEY_BASE + 1,
            KEY_BASE + 2,
            0
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferAmountAboveMaximum.selector,
                100
            )
        );
        moneroswap.createBuyOffer{value: 101}(
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            KEY_BASE + 3,
            KEY_BASE + 4,
            0
        );
    }

    function test_RevertWhen_NoPriceDefined() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            0, // MinimumBuyOffer,
            1 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoPriceDefined.selector
            )
        );
        moneroswap.createBuyOffer{value: 0}(
            address(0),
            0,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            KEY_BASE + 5,
            KEY_BASE + 6,
            0
        );
    }

    function test_RevertWhen_NoOracleDefined() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoPriceOracleDefined.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), 
            0, 
            100, 
            0, 
            1_000_000_000_000, 
            1 ether, 
            KEY_BASE + 7,
            KEY_BASE + 8,
            0
        );

    }

    function test_RevertWhen_PriceRatioWithFixedPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoPriceRatioWithFixedPrice.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),
            1 ether,
            100,
            0,
            1_000_000_000_000,
            1 ether,
            KEY_BASE + 9,
            KEY_BASE + 10,
            0
        );
    }

    function test_RevertWhen_PriceOffsetWithFixedPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoPriceOffsetWithFixedPrice.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),
            1 ether,
            0,
            1,
            1_000_000_000_000,
            1 ether,
            KEY_BASE + 11,
            KEY_BASE + 12,
            0
        );
    }

    function test_RevertWhen_MissingMaxPriceWithDynamicPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferMandatoryMaxpriceWithOraclePrice.selector
            )
        );

        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            0,                 // fixed price
            1,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            0,                 // max price
            KEY_BASE++,      // public spend key
            KEY_BASE++,      // public view key
            KEY_BASE++                  // msg pub key
        );
    }

    function test_RevertWhen_ActiveFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(11 ether, 1 ether);

        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferNoCreationWhenActiveFundingRequestExists.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_UsedPublicSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Check key 1, should unused
        vm.prank(ADDR_1);
        assertEq(moneroswap.isKeyUsed(1), false);
        
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        // Create a buy offer with keys 1/2/3
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // public spend key
            2,                 // public view key
            3                  // msg pub key
        );

        // Check key 1, should be used
        vm.prank(ADDR_1);
        assertEq(moneroswap.isKeyUsed(1), true);

        // Attempt to create another offer with pub spend key 2 (used public view key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector
            )
        );

        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            2,                 // public spend key
            4,                 // public view key
            5                  // msg pub key
        );

        // Attempt to create another offer with pub spend key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            3,                 // public spend key
            6,                 // public view key
            7                  // msg pub key
        );        
    }

    function test_RevertWhen_UsedPublicMessageKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        // Create a buy offer with keys 1/2/3
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // public spend key
            2,                 // public view key
            3                  // msg pub key
        );

        // Attempt to create another offer with pub message key 1 (used public spend key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );

        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            4,                 // public spend key
            5,                 // public view key
            1                  // msg pub key
        );

        // Attempt to create another offer with pub message key 2 (used public spend key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            6,                 // public spend key
            7,                 // public view key
            2                  // msg pub key
        ); 

        // Attempt to create another offer with pub message key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferUsedMessageKey.selector
            )
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            8,                 // public spend key
            9,                 // public view key
            3                  // msg pub key
        );                       
    }
    
    function testCreateBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Retrieve current liability
        uint256 liability = moneroswap.getLiability();
        
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.BUY,
            OfferState.OPEN
        );
        moneroswap.createBuyOffer{value: 1 ether}(
            address(1),        // counterparty
            3,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            4,                 // min XMR
            5,                 // max price
            KEY_BASE++,      // public spend key
            KEY_BASE++,      // public view key
            KEY_BASE++                  // msg pub key
        );

        // Retrieve the offer just created
        Offer memory offer = moneroswap.getBuyOffer(1);

        // Check that the offer is the one we just created
        assertEq(offer.id, 1);        
        assert(offer.type_ == OfferType.BUY);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.price, 3);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minxmr, 4);
        assertEq(offer.maxxmr, 0);
        // When using a fixed price, maxprice is forced to that fixed price
        assertEq(offer.maxprice, offer.price);
        assertEq(offer.minprice, 0);
        assertEq(offer.deposit, 1 ether);
        assertEq(offer.funded, false);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.evmPublicSpendKey, KEY_BASE - 3);
        assertEq(offer.evmPublicViewKey, KEY_BASE - 2);
        assertEq(offer.evmPublicMsgKey, KEY_BASE - 1);
        assertEq(offer.xmrPublicSpendKey, 0);
        assertEq(offer.xmrPrivateViewKey, 0);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.xmrPublicMsgKey, 0);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);
        assertEq(offer.index, 0);

        // Check that liability is now 1 ether
        assertEq(liability + 1 ether, moneroswap.getLiability());

        // Set a dummy oracle
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        // Now create a buy offer with a dynamic price
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(1),        // counterparty
            0,                 // fixed price
            1,                 // oracle ratio
            2,                 // oracle offset
            4,                 // min XMR
            5,                 // max price
            KEY_BASE++,      // public spend key
            KEY_BASE++,      // public view key
            KEY_BASE++                  // msg pub key
        );

        offer = moneroswap.getBuyOffer(2);

        // Check that the offer is the one we just created
        assertEq(offer.id, 2);        
        assert(offer.type_ == OfferType.BUY);
        assert(offer.state == OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, ADDR_1);
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.price, 0);
        assertEq(offer.oracleRatio, 1);
        assertEq(offer.oracleOffset, 2);
        assertEq(offer.minxmr, 4);
        assertEq(offer.maxprice, 5);
        assertEq(offer.minprice, 0);
        assertEq(offer.deposit, 1 ether);
        assertEq(offer.funded, false);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPublicSpendKey, KEY_BASE - 3);
        assertEq(offer.evmPublicViewKey, KEY_BASE - 2);
        assertEq(offer.evmPublicMsgKey, KEY_BASE - 1);
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
        assertEq(offer.index, 1);
    }
}