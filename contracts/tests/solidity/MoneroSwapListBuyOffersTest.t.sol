// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapListBuyOffersTest is Test {

    uint256 KEY_BASE = 100000000000000;
    
    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    
    function testListBuyOffers() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 N = 7;

        // Create N buy offers
        for (uint256 i = 0; i < N; i++) {
            vm.deal(ADDR_1, 1 ether);
            vm.prank(ADDR_1);
            moneroswap.createBuyOffer{value: 1 ether}(
                address(0),        // counterparty
                i + 1,             // fixed price
                0,                 // oracle ratio
                0,                 // oracle offset
                0,            // min XMR
                0,          // max price
                KEY_BASE + (i * 2),
                KEY_BASE + (i * 2) + 1,
                0                  // msg pub key
            );
        }

        // List buy offers by chunks of 2 with a step of 3
        for (uint256 i = 0; i < N + 4; i += 3) {
            Offer[] memory offers = moneroswap.listBuyOffers(i, 2);
           
            if (offers.length >= 1) {
                assertEq(offers[0].price, i + 1);
                assertEq(offers[0].index, i);
            }
            if (offers.length >= 2) {
                assertEq(offers[1].price, i + 2);
                assertEq(offers[1].index, i + 1);
            }
        }
    }
}