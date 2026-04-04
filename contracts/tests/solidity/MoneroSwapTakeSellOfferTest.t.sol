// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {Ed25519} from "../../src/Ed25519.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapTakeSellOfferTest is Test {
    uint256 KEY_BASE = 1000000000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);

    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;
    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;

    function test_RevertWhen_SellOfferUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to take a non existent sell offer
        vm.prank(ADDR_1);
        vm.expectRevert(ErrorSellOfferUnknown.selector);
        moneroswap.takeSellOffer(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 1, // publicspendkey
            KEY_BASE + 2 // privateviewkey
        );
    }

    function test_RevertWhen_SellOfferNotOpen() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // maxxmr
            KEY_BASE + 3, // public spend key
            KEY_BASE + 4 // public view key
        );

        // Take the offer so it is no longer takeable
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: 1 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 5, // publicspendkey
            KEY_BASE + 6 // privateviewkey
        );

        // Attempt to retake the offer
        vm.prank(ADDR_2);
        vm.expectRevert(abi.encodeWithSelector(ErrorSellOfferInvalidStateForTake.selector, OfferState.TAKEN));
        moneroswap.takeSellOffer(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 7, // publicspendkey
            KEY_BASE + 8 // privateviewkey
        );
    }

    function test_RevertWhen_InvalidCounterparty() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            ADDR_2, // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // maxxmr
            KEY_BASE + 9, // public spend key
            KEY_BASE + 10 // public view key
        );

        // Attempt to take the offer from an EOA which is not the specified counterparty
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        vm.expectRevert(abi.encodeWithSelector(ErrorSellOfferInvalidCounterparty.selector));
        moneroswap.takeSellOffer{value: 1 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 11, // publicspendkey
            KEY_BASE + 12 // privateviewkey
        );
    }

    function test_RevertWhen_PublicSpendKeyAlreadyUsed() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // maxxmr
            KEY_BASE + 13, // public spend key
            KEY_BASE + 14 // public view key
        );

        // Attempt to take the offer with a public spend key already used
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(abi.encodeWithSelector(ErrorSellOfferPublicSpendKeyAlreadyUsed.selector));
        moneroswap.takeSellOffer{value: 1 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 13, // publicspendkey
            KEY_BASE + 14 // privateviewkey
        );
    }

    function test_RevertWhen_XMRAmountBelowOfferMinimum() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            2_000_000_000_000, // maxxmr
            KEY_BASE + 17, // public spend key
            KEY_BASE + 18 // public view key
        );

        // Attempt to take the offer with a value too low
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferXMRAmountBelowOfferMinimum.selector, UNITS_PER_XMR / 2, 1_000_000_000_000
            )
        );
        moneroswap.takeSellOffer{value: 0.5 ether}(
            1, // offer id
            UNITS_PER_XMR / 2, // minxmr
            1 ether, // maxprice
            KEY_BASE + 19, // publicspendkey
            KEY_BASE + 20 // privateviewkey
        );
    }

    /// Test that the tx reverts if the bought amount is below what the taker specified
    function test_RevertWhen_XMRAmountTooLow() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            2_000_000_000_000, // maxxmr
            KEY_BASE + 21, // public spend key
            KEY_BASE + 22 // public view key
        );

        // Attempt to take the offer with a value too low
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(ErrorSellOfferXMRAmountTooLow.selector, UNITS_PER_XMR, UNITS_PER_XMR * 3 / 2)
        );
        moneroswap.takeSellOffer{value: 1 ether}(
            1, // offer id
            UNITS_PER_XMR * 3 / 2, // minxmr
            1 ether, // maxprice
            KEY_BASE + 23, // publicspendkey
            KEY_BASE + 24 // privateviewkey
        );
    }

    function test_RevertWhen_UsedPublicSpendKey() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            2_000_000_000_000, // maxxmr
            1, // public spend key
            2 // public view key
        );

        (uint256 x, uint256 y) = Ed25519.scalarMultBase(2);
        uint256 pubViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));

        // Attempt to create another offer with pub spend key 2 (used public view key)
        vm.prank(ADDR_1);
        vm.expectRevert(abi.encodeWithSelector(ErrorSellOfferPublicSpendKeyAlreadyUsed.selector));

        moneroswap.takeSellOffer{value: 3 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            pubViewKey, // publicspendkey
            4 // publicViewKey
        );

        // Attempt to create another offer with pub spend key 3 (used public message key)
        vm.prank(ADDR_1);
        vm.expectRevert(abi.encodeWithSelector(ErrorSellOfferPublicSpendKeyAlreadyUsed.selector));
        moneroswap.takeSellOffer{value: 3 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            3, // publicspendkey
            6 // publicViewKey
        );
    }

    function test_AmountAboveMaximum_Funded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        ///
        /// Create a funding request
        ///

        // Now create an offer with a funding request
        uint256 fundingAmount = vm.randomUint(1 ether, 4 ether);
        vm.deal(ADDR_1, fundingAmount / 2);
        vm.prank(ADDR_1);
        uint256 fee = fundingAmount / 10;
        moneroswap.createFundingRequest(fundingAmount, fee);

        // Fund the funding request
        vm.deal(ADDR_2, fundingAmount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: fundingAmount}(ADDR_1);

        ///
        /// Create a funded sell offer
        ///
        // Attempt to create a sell offer with a minimum amount of XMR which is too low to cover the funding fee
        uint256 minxmr = 1_000_000_000_000; // 1 XMR
        uint256 maxxmr = 5_000_000_000_000; // 5 XMR

        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0), // counterparty
            1 ether, // fixed price
            minxmr, // min XMR
            maxxmr, // max XMR
            KEY_BASE + 25, // public spend key
            KEY_BASE + 26 // public view key
        );

        ///
        /// Take the offer with an amount above the maximum
        ///

        uint256 liability = moneroswap.getLiability();

        uint256 value = fundingAmount * 2;

        // Change chainId, this will trigger the refund of the amount delta
        vm.chainId(1);
        vm.deal(ADDR_3, fundingAmount * 2);
        vm.prank(ADDR_3);

        moneroswap.takeSellOffer{value: value}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 27, // publicspendkey
            KEY_BASE + 28 // privateviewkey
        );

        // Read the offer just created
        Offer memory offer = moneroswap.getSellOffer(1);

        assertTrue(offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR <= offer.maxamount);

        assertEq(offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR, offer.takerDeposit);
        assertEq(liability + (offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR), moneroswap.getLiability());

        assertEq(ADDR_3.balance, value - (offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR));
    }

    function test_AmountAboveMaximum() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        ///
        /// Create a sell offer
        ///

        uint256 maxamount = vm.randomUint(1 ether, 2 ether);

        // Attempt to create a sell offer with a minimum amount of XMR which is too low to cover the funding fee
        uint256 minxmr = 1_000_000_000_000; // 1 XMR
        uint256 maxxmr = 50_000_000_000_000; // 5 XMR

        vm.deal(ADDR_1, maxamount * 2);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: maxamount}(
            address(0), // counterparty
            1 ether, // fixed price
            minxmr, // min XMR
            maxxmr, // max XMR
            KEY_BASE + 29, // public spend key
            KEY_BASE + 30 // public view key
        );

        ///
        /// Take the offer with an amount above the maximum
        ///

        uint256 liability = moneroswap.getLiability();

        uint256 value = maxamount * 2;
        vm.chainId(1);
        vm.deal(ADDR_3, value);
        vm.prank(ADDR_3);

        moneroswap.takeSellOffer{value: value}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 31, // publicspendkey
            KEY_BASE + 32 // privateviewkey
        );

        // Read the offer just created
        Offer memory offer = moneroswap.getSellOffer(1);

        assertTrue(offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR <= offer.maxamount);

        assertEq(offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR, offer.takerDeposit);
        assertEq(liability + (offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR), moneroswap.getLiability());

        assertEq(ADDR_3.balance, value - (offer.finalxmr * offer.finalprice / Utils.UNITS_PER_XMR));
    }

    function testTakeSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 2 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 2 ether}(
            address(0), // counterparty
            1 ether, // price
            1_000_000_000_000, // min XMR
            2_000_000_000_000, // maxxmr
            KEY_BASE + 33, // public spend key
            KEY_BASE + 34 // public view key
        );

        uint256 liability = moneroswap.getLiability();
        assertEq(liability, 2 ether);

        // Take the offer
        vm.deal(ADDR_2, 3 ether);
        vm.prank(ADDR_2);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(1, OfferType.SELL, OfferState.TAKEN);
        // Take the offer with a deposit of 3 ethers, we should receive the delta back
        moneroswap.takeSellOffer{value: 3 ether}(
            1, // offer id
            UNITS_PER_XMR, // minxmr
            1 ether, // maxprice
            KEY_BASE + 35, // publicspendkey
            KEY_BASE + 36 // privateviewkey
        );

        MoneroSwap.Parameters memory PARAMETERS = moneroswap.getParameters();

        // Retrieve the offer
        Offer memory offer = moneroswap.getSellOffer(1);
        assert(offer.state == OfferState.TAKEN);
        assertEq(offer.counterparty, ADDR_2);
        assertEq(offer.blockTaken, block.number);
        assertEq(offer.takerDeposit, 2 ether);
        assertEq(offer.finalprice, 1 ether);
        assertEq(offer.finalxmr, 2 * UNITS_PER_XMR); // The settled amount is the maximum provided by the seller
        assertEq(offer.evmPublicSpendKey, KEY_BASE + 35);
        assertEq(offer.evmPublicViewKey, KEY_BASE + 36);
        assertEq(offer.t0, block.timestamp + PARAMETERS.T0_DELAY);
        assertEq(offer.t1, offer.t0 + PARAMETERS.T1_DELAY);

        // Check liability
        assertEq(moneroswap.getLiability(), liability + 2 ether);

        assertEq(ADDR_2.balance, 1 ether); // 3 - 2 = 1
    }
}
