// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";

/// Tests related to FundingRequest
contract MoneroSwapFundFundingRequestTest is Test {

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    function test_RevertWhen_FundingRequestUnknown() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.expectRevert(MoneroSwap.ErrorFundingRequestNotFound.selector);
        moneroswap.fundFundingRequest(ADDR_1);
    }

    function test_RevertWhen_SelfFunding() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Attempt to fund the FundingRequest with self
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestCannotSelfFund.selector);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);
    }

    function test_RevertWhen_FundingRequestAlreadyFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the FundingRequest
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Attempt to fund the FundingRequest again
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestAlreadyFunded.selector);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);
    }

    function test_RevertWhen_IncorrectAmount() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Attempt to fund the FundingRequest with an incorrect amount
        vm.deal(ADDR_2,2 ether);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
            MoneroSwap.ErrorFundingRequestIncorrectAmount.selector,
            2 ether,
            1 ether
        ));
        moneroswap.fundFundingRequest{value: 2 ether}(ADDR_1);  
    }

    function testFundFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        // Create a FundingRequest
        vm.deal(ADDR_1, 1 ether - 1 wei);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        // Fund the FundingRequest
        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        // Check that the funder is set
        assertEq(moneroswap.getFundingRequest(ADDR_1).funder, ADDR_2);

        // Check that the liability is updated
        assertEq(moneroswap.getLiability(), 1 ether);
    }
}