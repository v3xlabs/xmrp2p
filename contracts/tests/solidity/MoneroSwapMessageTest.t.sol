// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import "../../src/Errors.sol";
import "../../src/Errors.sol";

import {Utils} from "./Utils.t.sol";

/// The test only consider a buy offer, but given the message implementation is symetric this should be considered OK
contract MoneroSwapMessageTest is Test {

    uint256 KEY_BASE = 1000000000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);
    
    function test_RevertIf_InvalidOffer() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.expectRevert(ErrorInvalidOffer.selector);
        moneroswap.message(0, "");
    }

    function test_RevertIf_NotOwner() public {        
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        vm.prank(ADDR_2);
        vm.expectRevert(ErrorInvalidOffer.selector);
        moneroswap.message(1, "");
    }     

    function test_RevertIf_NotCounterparty() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take the buy offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{ value: 1 ether}(
            1, // id
            1_000_000_000_000, // max XMR
            1 ether, // min price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        vm.prank(ADDR_3);
        vm.expectRevert(ErrorInvalidOffer.selector);
        moneroswap.message(1, "");
    }     

    /// An offer may have no message key because it was voluntarily set to 0 or because it is not yet taken
    function test_RevertIf_NoMessageKeysSet() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer without message keys
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            0 // msg pub key
        );

        vm.prank(ADDR_1);
        vm.expectRevert(ErrorMissingMessageKeys.selector);
        moneroswap.message(1, "");

        // Create a buy offer with message key  
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            0 // msg pub key
        );

        vm.prank(ADDR_1);
        vm.expectRevert(ErrorMissingMessageKeys.selector);
        moneroswap.message(2, "");

        // Now take the offer without setting keys
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{ value: 1 ether}(
            2, // id
            1_000_000_000_000, // max XMR
            1 ether, // min price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            0 // msg pub key
        );

        vm.prank(ADDR_2);
        vm.expectRevert(ErrorMissingMessageKeys.selector);
        moneroswap.message(2, "");


        vm.prank(ADDR_1);
        vm.expectRevert(ErrorMissingMessageKeys.selector);
        moneroswap.message(2, "");
    } 

    function testMessage() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a buy offer
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        moneroswap.createBuyOffer{value: 1 ether}(
            address(0), // counterparty
            1 ether, // fixed price
            0, // oracle ratio
            0, // oracle offset
            1_000_000_000_000, // min XMR
            1 ether, // max price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Take the buy offer
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.takeBuyOffer{ value: 1 ether}(
            1, // id
            1_000_000_000_000, // max XMR
            1 ether, // min price
            KEY_BASE++, // public spend key
            KEY_BASE++, // public view key
            KEY_BASE++ // msg pub key
        );

        // Message the offer from the owner
        vm.prank(ADDR_1);
        vm.expectEmit(true,true,true,true);
        emit MoneroSwap.MessageEvent(1, "Hello counterparty");        
        moneroswap.message(1, "Hello counterparty");

        // Message the offer from the counterparty
        vm.prank(ADDR_2);
        vm.expectEmit(true,true,true,true);
        emit MoneroSwap.MessageEvent(1, "Hello owner");
        moneroswap.message(1, "Hello owner");


    }    
}