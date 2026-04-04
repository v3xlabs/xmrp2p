// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../src/MoneroSwap.sol";
import "../../src/Errors.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";

/// Tests related to FundingRequest
contract MoneroSwapDefundFundingRequestTest is Test {

    uint256 KEY_BASE = 1000000000000;

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);
    address ADDR_3 = address(0x3333333333333333333333333333333333333333);


    function test_RevertWhen_RequestInUse() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Create a sell offer using the Funding Request
        vm.prank(ADDR_1);
        moneroswap.createSellOffer{value: 0}(
            address(0),
            1 ether,
            0,
            0,
            KEY_BASE + 1,
            KEY_BASE + 2,
            0
        );

        vm.prank(ADDR_2);
        vm.expectRevert(ErrorFundingRequestInUse.selector);
        moneroswap.defundFundingRequest(ADDR_1);
    }

    function test_RevertWhen_NotFunder() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        vm.prank(ADDR_2);
        vm.expectRevert(ErrorFundingRequestDefundableOnlyByFunder.selector);
        moneroswap.defundFundingRequest(ADDR_1);
    }

    function test_RevertWhen_Unknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.prank(ADDR_1);
        vm.expectRevert(ErrorFundingRequestDefundableOnlyByFunder.selector);
        moneroswap.defundFundingRequest(ADDR_2);
    }

    function testDefundFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the funding request
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Check the liability
        assertEq(moneroswap.getLiability(), 1 ether);

        vm.prank(ADDR_2);
        moneroswap.defundFundingRequest(ADDR_1);

        // Check the liability
        assertEq(moneroswap.getLiability(), 0);
        // Check the balance
        assertEq(1 ether, ADDR_2.balance);
        // Check the funding request    
        
        
        FundingRequest memory freq = moneroswap.getFundingRequest(ADDR_1);
        assertEq(0, freq.fundedOn);
        assertEq(address(0), freq.funder);
    }
}