// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";
import {DummyPriceOracle} from "./DummyPriceOracle.t.sol";
import {Ed25519} from "../../main/solidity/Ed25519.sol";

import {Utils} from "./Utils.t.sol";

/// Tests for testing scenarios related to the use of the refund function
contract MoneroSwapCreateSellOfferTest is Test {

    uint256 KEY_BASE = 10000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;
    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;

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
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.SELL, MoneroSwap.OfferState.OPEN);
        moneroswap.createSellOffer{value: evmDeposit}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1,                // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            KEY_BASE++                  // msg pub key
        );

        // Attempt to create another offer with the same public spend key
        vm.prank(ADDR_1);       
        vm.expectRevert(MoneroSwap.ErrorSellOfferPublicSpendKeyAlreadyUsed.selector);
        moneroswap.createSellOffer{value: evmDeposit}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1,                // maxxmr
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            KEY_BASE++                  // msg pub key
        );
    }

    function test_RevertWhen_SellOfferMaxBookSizeReached() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        // Set parameters to limit offer book size to 1
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            0, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            10 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
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
        emit MoneroSwap.OfferEvent(1, MoneroSwap.OfferType.SELL, MoneroSwap.OfferState.OPEN);
        moneroswap.createSellOffer{value: evmDeposit}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // max price
            1, // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            KEY_BASE++                  // msg pub key
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
                MoneroSwap.ErrorSellOfferMaximumOfferBookSizeReached.selector,
                1
            )
        );
        moneroswap.createSellOffer{value: evmDeposit}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000,            // min XMR
            1 ether,          // min price
            1, // max XMR
            xmrPublicSpendKey,
            xmrPrivateViewKey,
            KEY_BASE++                  // msg pub key
        );
    }

    function test_RevertWhen_AmountNotInRange() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            10, // MinimumSellOffer,
            100, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAmountBelowMinimum.selector,
                10
            )
        );
        moneroswap.createSellOffer{value: 1}(
            address(0),
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++);

        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAmountAboveMaximum.selector,
                100
            )
        );
        moneroswap.createSellOffer{value: 101}(
            address(0),
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_NoPriceDefined() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoPriceDefined.selector
            )
        );
        moneroswap.createSellOffer{value: 1}(
            address(0),
            address(0),
            0,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_NoOracleDefined() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        vm.prank(msg.sender);
        moneroswap.setParameters(
            1, // FundingRequestMaxBalance,
            0, // FundingRequestMinFeeRatio
            1, // MaximumBuyOfferBookSize,
            1, // MinimumBuyOffer,
            1 ether, // MaximumBuyOffer,
            1, // MaximumSellOfferBookSize,
            1, // MinimumSellOffer,
            1 ether, // MaximumSellOffer,
            1_000_000_000, // SellOfferCoverageRatio,
            86400, // T0Delay,
            86400 // T1Delay
        );
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoPriceOracleDefined.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),
            address(0),
            0,
            100,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );

    }

    function test_RevertWhen_PriceRatioWithFixedPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoPriceRatioWithFixedPrice.selector
            )
        );

        moneroswap.createSellOffer{value: 1 ether}(
            address(0), 
            address(0), 
            1 ether,
            100,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_PriceOffsetWithFixedPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoPriceOffsetWithFixedPrice.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),
            address(0), 
            1 ether,
            0,
            1,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_MissingMinPriceWithDynamicPrice() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferMandatoryMinpriceWithOraclePrice.selector
            )
        );

        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            0,                 // fixed price
            1,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            0,                 // min price
            1,                 // max XMR
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

        // Call to createSellOffer should revert when sending value while a FundingRequest exists
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAvailableFundingRequest.selector
            )
        );

        moneroswap.createSellOffer{value: 1 ether}(
            address(0),
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE++,
            KEY_BASE++,
            KEY_BASE++
        );
    }

    function test_RevertWhen_FixedPriceAndAmountTooLowForFundingFee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Now create an offer with a funding request
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        uint256 price = 1;
        uint256 minxmr = (fee * Utils.UNITS_PER_XMR)/ price;
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            address(2),        // manager
            price,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            minxmr -1,         // min XMR
            5,                 // min price
            6,                 // max XMR
            KEY_BASE++,      // public spend key
            KEY_BASE++,      // public view key
            KEY_BASE++                  // msg pub key
        );
    }

    function test_RevertWhen_DynamicPriceAndAmountTooLowForFundingFee() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Set a dummy oracle
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        // Now create an offer with a funding request
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
        moneroswap.createFundingRequest(1 ether, fee);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        uint256 minprice = 2;
        uint256 minxmr = (fee * Utils.UNITS_PER_XMR)/ minprice;
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );

        // Attempt to create a sell offer with a minimum amount of XMR which is too low to cover the funding fee
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            address(2),        // manager
            0,                 // fixed price
            1,                 // oracle ratio
            0,                 // oracle offset
            minxmr -1,         // min XMR 
            minprice,          // min price
            6,                 // max XMR
            KEY_BASE++,      // public spend key
            KEY_BASE++,      // public view key
            KEY_BASE++                  // msg pub key
        );     

        // Attempt to create a sell offer with a minimum price which is too low to cover the funding fee
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferAmountTooLowToCoverFundingFee.selector
            )
        );
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(1),        // counterparty
            address(2),        // manager
            0,                 // fixed price
            1,                 // oracle ratio
            0,                 // oracle offset
            minxmr,            // min XMR
            minprice - 1,      // min price
            6,                 // max XMR
            KEY_BASE++,      // public spend key
            KEY_BASE++,     // public view key
            KEY_BASE++                  // msg pub key
        );    
    }

    function testCreateSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Retrieve current liability
        uint256 liability = moneroswap.getLiability();
        uint256 xmrDeposit = 1 ether;

        vm.deal(ADDR_1, 2 * xmrDeposit);
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            MoneroSwap.OfferType.SELL,
            MoneroSwap.OfferState.OPEN
        );
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(1),        // counterparty
            address(2),        // manager
            3,                 // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            4,                 // min XMR
            5,                 // min price
            9,                 // max XMR
            KEY_BASE++,     // public spend key
            KEY_BASE++,     // public view key
            KEY_BASE++                  // msg pub key
        );

        // Retrieve the offer just created
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);

        // Check that the offer is the one we just created
        assertEq(offer.id, 1);        
        assert(offer.type_ == MoneroSwap.OfferType.SELL);
        assert(offer.state == MoneroSwap.OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, address(2));
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.price, 3);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minxmr, 4);
        assertEq(offer.maxxmr, 9);
        assertEq(offer.maxprice, 0);
        // When using a fixed price, minprice is forced to that fixed price
        assertEq(offer.minprice, offer.price);
        assertEq(offer.deposit, xmrDeposit);
        assertEq(offer.funded, false);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.evmPublicSpendKey, 0);
        assertEq(offer.evmPublicViewKey, 0);
        assertEq(offer.evmPublicMsgKey, 0);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE - 3);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE - 2);
        assertEq(offer.xmrPublicMsgKey, KEY_BASE - 1);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.index, 0);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);


        // Check that liability is now the xmrDeposit
        assertEq(liability + xmrDeposit, moneroswap.getLiability());

        // Set a dummy oracle
        DummyPriceOracle oracle = new DummyPriceOracle(8, 100, block.timestamp);
        vm.prank(msg.sender);
        moneroswap.setPriceOracle(address(oracle), 100);

        // Now create a buy offer with a dynamic price
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(1),        // counterparty
            address(2),        // manager
            0,                 // fixed price
            1,                 // oracle ratio
            2,                 // oracle offset
            4,                 // min XMR
            5,                 // min price
            9,                 // max XMR
            KEY_BASE++,     // public spend key
            KEY_BASE++,     // public view key
            KEY_BASE++                  // msg pub key
        );

        offer = moneroswap.getSellOffer(2);

        // Check that the offer is the one we just created
        assertEq(offer.id, 2);        
        assert(offer.type_ == MoneroSwap.OfferType.SELL);
        assert(offer.state == MoneroSwap.OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, address(2));
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.price, 0);
        assertEq(offer.oracleRatio, 1);
        assertEq(offer.oracleOffset, 2);
        assertEq(offer.minxmr, 4);
        assertEq(offer.maxxmr, 9);
        assertEq(offer.maxprice, 0);
        assertEq(offer.minprice, 5);
        assertEq(offer.deposit, xmrDeposit);
        assertEq(offer.funded, false);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.evmPublicSpendKey, 0);
        assertEq(offer.evmPublicViewKey, 0);
        assertEq(offer.evmPublicMsgKey, 0);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE - 3);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE - 2);
        assertEq(offer.xmrPublicMsgKey, KEY_BASE - 1);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.index, 1);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);

    }

    function testCreateSellOfferWithFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Now create an offer with a funding request
        vm.deal(ADDR_1, 0.1 ether);
        vm.prank(ADDR_1);
        uint256 fee = 1 ether - vm.randomUint(1, 1 ether);
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
            address(2),        // manager
            price,             // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            minxmr,            // min XMR (so minprice & minxmr >= fee), given minprice is forced to price (1)
            5,                 // min price
            6,                 // max XMR
            KEY_BASE + 15,     // public spend key
            KEY_BASE + 16,     // public view key
            9                  // msg pub key
        );

        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);

        // Check that the offer is the one we just created
        assertEq(offer.id, 1);        
        assert(offer.type_ == MoneroSwap.OfferType.SELL);
        assert(offer.state == MoneroSwap.OfferState.OPEN);
        assertEq(offer.owner, ADDR_1);
        assertEq(offer.manager, address(2));
        assertEq(offer.maxamount, 1 ether);
        assertEq(offer.price, price);
        assertEq(offer.oracleRatio, 0);
        assertEq(offer.oracleOffset, 0);
        assertEq(offer.minxmr, minxmr);
        assertEq(offer.maxxmr, 6);
        assertEq(offer.maxprice, 0);
        assertEq(offer.minprice, price);
        assertEq(offer.deposit, 0);
        assertEq(offer.funded, true);
        assertEq(offer.id, moneroswap.getFundingRequest(ADDR_1).usedby);
        assertEq(offer.counterparty, address(1));
        assertEq(offer.lastupdate, block.timestamp);
        assertEq(offer.blockTaken, 0);
        assertEq(offer.evmPrivateSpendKey, 0);
        assertEq(offer.evmPrivateViewKey, 0);
        assertEq(offer.evmPublicSpendKey, 0);
        assertEq(offer.evmPublicViewKey, 0);
        assertEq(offer.evmPublicMsgKey, 0);
        assertEq(offer.xmrPublicSpendKey, KEY_BASE + 15);
        assertEq(offer.xmrPrivateViewKey, KEY_BASE + 16);
        assertEq(offer.xmrPublicMsgKey, 9);
        assertEq(offer.xmrPrivateSpendKey, 0);
        assertEq(offer.index, 0);
        assertEq(offer.finalprice, 0);
        assertEq(offer.takerDeposit, 0);
        assertEq(offer.finalxmr, 0);
        assertEq(offer.t0, 0);
        assertEq(offer.t1, 0);
    }

    function testCreateSellOfferCoverageRatio() public {
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

        vm.deal(ADDR_1, 10 ether);
        uint256 deposit = 10 + vm.randomUint(1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: deposit}(
            address(0),
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE + 17,
            KEY_BASE + 18,
            0);

        // Retrieve offer
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);

        assertEq((deposit * RATIO_DENOMINATOR) / coverageRatio, offer.maxamount);

        //
        // Now do the same with a FundingRequest
        //

        deposit = 0.1 ether + vm.randomUint(1, 1 ether);
        vm.deal(ADDR_1, deposit - 5);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(deposit, 0.1 ether);

        // Take the funding request
        vm.deal(ADDR_2, deposit + 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: deposit}(ADDR_1);

        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),
            address(0),
            1 ether,
            0,
            0,
            1_000_000_000_000,
            1 ether,
            1,
            KEY_BASE + 19,
            KEY_BASE + 20,
            0);

        // Retrieve offer
        offer = moneroswap.getSellOffer(2);

        assertEq(offer.funded, true);
        assertEq(offer.id, moneroswap.getFundingRequest(ADDR_1).usedby);
        assertEq((deposit * RATIO_DENOMINATOR) / coverageRatio, offer.maxamount);


    }

    function test_RevertWhen_NoFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferNoFundingRequest.selector
            )
        );

        // Send no value
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 21,     // public spend key
            KEY_BASE + 22,     // public view key
            0                  // msg pub key
        );
    }

    function test_RevertWhen_NoFundedFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0.1 ether);

        // Send no value
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferFundingRequestNotFunded.selector
            )
        );

        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 23,     // public spend key
            KEY_BASE + 24,     // public view key
            0                  // msg pub key
        );
    }

    function test_RevertWhen_FundingRequestAlreadyInUse() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0.1 ether);

        // Fund the funding request
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);        
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Create an offer which will use that funding request
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 25,     // public spend key
            KEY_BASE + 26,     // public view key
            0                  // msg pub key
        );

        assertEq(1, moneroswap.getFundingRequest(ADDR_1).usedby);
        
        // Send no value
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferFundingRequestAlreadyInUse.selector
            )
        );

        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 27,     // public spend key
            KEY_BASE + 28,     // public view key
            0                  // msg pub key
        );
    }

    function test_RevertWhen_UsedPublicSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        // Create a buy offer with keys 1/2/3
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR
            1,                 // public spend key
            2,                 // private view key
            3                  // msg pub key
        );

        (uint256 x,uint256 y) = Ed25519.scalarMultBase(2);
        uint256 pubViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x,y));
        
        // Attempt to create another offer with pub spend key 2 (used private view key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
            pubViewKey,        // public spend key
            4,                 // private view key
            5                  // msg pub key
        );

        // Attempt to create another offer with pub spend key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferPublicSpendKeyAlreadyUsed.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
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
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
            1,                 // public spend key
            2,                 // private view key
            3                  // msg pub key
        );

        // Attempt to create another offer with pub message key 1 (used public spend key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferUsedMessageKey.selector
            )
        );

        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
            4,                 // public spend key
            5,                 // private view key
            1                  // msg pub key
        );

        (uint256 x,uint256 y) = Ed25519.scalarMultBase(2);
        uint256 pubViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x,y));

        // Attempt to create another offer with pub message key  = used public view key
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferUsedMessageKey.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
            6,                 // public spend key
            7,                 // private view key
            pubViewKey         // msg pub key
        ); 

        // Attempt to create another offer with pub message key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorSellOfferUsedMessageKey.selector
            )
        );
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // max price
            1,                 // max XMR            
            8,                 // public spend key
            9,                 // private view key
            3                  // msg pub key
        );                       
    }

    function testCancelSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 xmrDeposit = 1 ether + (vm.randomUint() % 1 ether);

         // Create an offer which will use that funding request
        vm.deal(ADDR_1, xmrDeposit);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: xmrDeposit}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 29,     // public spend key
            KEY_BASE + 30,     // public view key
            0                  // msg pub key
        );

        // Cancel the offer
        vm.prank(ADDR_1);
        moneroswap.cancelSellOffer(1);

        // Check that the contract's liability is now 0
        assertEq(0, moneroswap.getLiability());
        // Check that the address balance has increased by the deposit
        assertEq(xmrDeposit, ADDR_1.balance);
 
        // Check that the offer is cancelled
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);

        assertTrue(MoneroSwap.OfferState.CANCELLED == offer.state);
    }

    function testCancelSellOfferFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0.1 ether);

        // Fund the funding request
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);        
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);
        assertEq(1 ether, moneroswap.getLiability());

        // Create an offer which will use that funding request
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            address(0),        // manager
            1 ether,           // fixed price
            0,                 // oracle ratio
            0,                 // oracle offset
            1_000_000_000_000, // min XMR
            1 ether,           // min price
            1,                 // max XMR
            KEY_BASE + 31,     // public spend key
            KEY_BASE + 32,     // public view key
            0                  // msg pub key
        );

        // Check that the funding request was used for creating this offer
        assertEq(1, moneroswap.getFundingRequest(ADDR_1).usedby);
        assert(moneroswap.getSellOffer(1).funded);

        // Cancel the offer
        vm.prank(ADDR_1);
        moneroswap.cancelSellOffer(1);

        // Check that the funding request is no longer used
        assertEq(0, moneroswap.getFundingRequest(ADDR_1).usedby);
 
        // Check that the offer is cancelled
        MoneroSwap.Offer memory offer = moneroswap.getSellOffer(1);
        assertTrue(MoneroSwap.OfferState.CANCELLED == offer.state);

        // Check that the contract's liability is still the amount of the FundingRequest
        assertEq(1 ether, moneroswap.getLiability());
    }
}