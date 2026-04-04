// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import "../../src/Errors.sol";
import "../../src/Errors.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapCancelBuyOfferTest is Test {

    uint256 KEY_BASE = 0;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);

    function test_RevertWhen_UnknownOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.prank(ADDR_1);
        vm.expectRevert(ErrorBuyOfferUnknown.selector);
        moneroswap.cancelBuyOffer(1);
    }

    function test_ReverIf_NotOfferOwner() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,             // fixed price
            1_000_000_000_000,            // min XMR
            KEY_BASE++,
            KEY_BASE++
        );

        // Attempt to cancel the offer from ADDR_3
        vm.deal(ADDR_3, 1 ether);
        vm.prank(ADDR_3);
        vm.expectRevert(ErrorBuyOfferNotOwner.selector);
        moneroswap.cancelBuyOffer(1);
    }

    function test_RevertIf_NotOpen() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,             // fixed price
            1_000_000_000_000,            // min XMR
            KEY_BASE++,
            KEY_BASE++
        );

        // Take the offer
        vm.deal(ADDR_2, 2 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{value: 1 ether}(
            1,                 // offer id
            1_000_000_000_000, // maxxmr
            1 ether,           // minprice
            KEY_BASE++,      // publicspendkey
            KEY_BASE++      // privateviewkey
        );

        // Attempt to cancel the offer
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ErrorBuyOfferInvalidStateForCancel.selector,
                OfferState.TAKEN
            )
        );
        moneroswap.cancelBuyOffer(1);
    }

    function testCancelBuyOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);

        moneroswap.createBuyOffer{value: 1 ether}(
            address(0),        // counterparty
            1 ether,             // fixed price
            1_000_000_000_000,            // min XMR
            KEY_BASE++,
            KEY_BASE++
        );

        uint256 liability = moneroswap.getLiability();
        assertEq(liability, 1 ether);
        uint256 balance = ADDR_1.balance;
        
        // Cancel the offer
        vm.prank(ADDR_1);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.OfferEvent(
            1,                 // offer id
            OfferType.BUY,
            OfferState.CANCELLED
        );
        moneroswap.cancelBuyOffer(1);

        liability = moneroswap.getLiability();
        assertEq(liability, 0);
        assertEq(balance + 1 ether, ADDR_1.balance);        
    }
}