// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapCancelSellOfferTest is Test {

    uint256 KEY_BASE = 100;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);

    function test_RevertWhen_OfferUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Attempt to cancel an unknown offer
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferUnknown.selector
            )
        );
        moneroswap.cancelSellOffer(1);
    }

    function test_RevertWhen_NotCancellableByCaller() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a sell offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,           // fixed price
            1_000_000_000_000, // min XMR
            1,                 // max XMR
            KEY_BASE + 1,      // public spend key
            KEY_BASE + 2      // public view key
        );

        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferNotCancellableByCaller.selector
            )
        );
        moneroswap.cancelSellOffer(1);
    }

    function test_RevertWhen_InvalidState() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 deposit = 1 ether + (vm.randomUint() % (0.5 ether));
        // Create a sell offer
        vm.deal(ADDR_1, deposit);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: deposit}(
            address(0),        // counterparty
            deposit,           // fixed price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // max XMR
            KEY_BASE + 3,      // public spend key
            KEY_BASE + 4      // public view key
        );

        // Take the sell offer so it is no longer in state OPEN
        vm.deal(ADDR_2, deposit);
        vm.prank(ADDR_2);
        moneroswap.takeSellOffer{value: deposit}(
            1,
            1_000_000_000_000, // min XMR
            deposit,           // max price
            KEY_BASE + 5,      // public spend key
            KEY_BASE + 6      // public view key
        );

        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorSellOfferInvalidStateForCancel.selector,
                OfferState.TAKEN
            )
        );
        moneroswap.cancelSellOffer(1);
    }

    function test_cancelSellOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 deposit = 1 ether + (vm.randomUint() % (0.5 ether));
        // Create a sell offer
        vm.deal(ADDR_1, deposit);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: deposit}(
            address(0),        // counterparty
            deposit,           // fixed price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // max XMR
            KEY_BASE + 7,      // public spend key
            KEY_BASE + 8      // public view key
        );

        uint256 balance = address(ADDR_1).balance;
        uint256 liability = moneroswap.getLiability();

        vm.prank(ADDR_1);
        moneroswap.cancelSellOffer(1);
        assertEq(balance + deposit, address(ADDR_1).balance);
        assertEq(liability - deposit, moneroswap.getLiability());
    }

    function test_cancelSellOfferFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 amount = 1 ether + (vm.randomUint() % (0.5 ether));

        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, 0);

        // Fund the funding request
        vm.deal(ADDR_2, amount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: amount}(ADDR_1);

        // Create a sell offer
        vm.deal(ADDR_1, amount);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            amount,           // fixed price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // max XMR
            KEY_BASE + 9,      // public spend key
            KEY_BASE + 10     // public view key
        );

        uint256 balance = address(ADDR_1).balance;
        uint256 liability = moneroswap.getLiability();

        vm.prank(ADDR_1);
        moneroswap.cancelSellOffer(1);
        // Check that ADDR_1 has still the same balance
        assertEq(balance, address(ADDR_1).balance);
        // Check that the liability didn't change
        assertEq(liability, moneroswap.getLiability());
        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
        assertEq(0, freq.usedby);
    }

    function test_cancelSellOfferFundedByFunder() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 amount = 1 ether + (vm.randomUint() % (0.5 ether));

        // Create a funding request
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, 0);

        // Fund the funding request
        vm.deal(ADDR_2, amount * 2);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: amount}(ADDR_1);

        // Create a sell offer
        vm.deal(ADDR_1, amount);
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),        // counterparty
            amount,           // fixed price
            1_000_000_000_000, // min XMR
            1_000_000_000_000, // max XMR
            KEY_BASE + 11,     // public spend key
            KEY_BASE + 12     // public view key
        );

        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
        MoneroSwap.Parameters memory params = moneroswap.getParameters();

        // Attempt to cancel the sell offer too early
        vm.prank(ADDR_2);
        vm.warp(freq.fundedOn + 2 * (params.T0_DELAY + params.T1_DELAY));
        vm.expectRevert(ErrorSellOfferNotCancellableByCaller.selector);
        moneroswap.cancelSellOffer(1);

        vm.warp(freq.fundedOn + 2 * (params.T0_DELAY + params.T1_DELAY) + 1);

        // Cancel the sell offer
        uint256 balance = address(ADDR_1).balance;
        uint256 liability = moneroswap.getLiability();

        vm.prank(ADDR_2);
        moneroswap.cancelSellOffer(1);
        // Check that ADDR_1 has still the same balance
        assertEq(balance, address(ADDR_1).balance);
        // Check that the liability didn't change
        assertEq(liability, moneroswap.getLiability());
        freq = moneroswap.getFundingRequest(ADDR_1);
        assertEq(0, freq.usedby);
    }
}