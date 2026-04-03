// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";
import {Utils} from "./Utils.t.sol";

/// Tests related to FundingRequest
contract MoneroSwapFundingRequestTest is Test {

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    /// Instance of the MoneroSwap contract used for testing
    MoneroSwap public moneroswap;

    /// set up function which creates the MoneroSwap instance used during the tests
    function setUp() public {
        moneroswap = new MoneroSwap(msg.sender);
    }

    function test_RevertIf_AlreadyExists() public {
        // Create a first FundingRequest for ADDR_1
        vm. startPrank(tx.origin);
        moneroswap.createFundingRequest(msg.sender.balance + 1, 0);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestAlreadyExistsForAddress.selector);
        moneroswap.createFundingRequest(msg.sender.balance + 1, 0);
        vm.stopPrank();
    }

    function test_RevertIf_NotAnEOA() public {
        vm.expectRevert(MoneroSwap.ErrorFundingRequestNotAnEOA.selector);
        moneroswap.createFundingRequest(0, 0);
    }

    function test_RevertIf_AmountZero() public {
        // Create a first FundingRequest for ADDR_1
        vm. startPrank(tx.origin);
        vm.expectRevert(MoneroSwap.ErrorFundingRequestZero.selector);
        moneroswap.createFundingRequest(0, 0);
        vm.stopPrank();
    }

    function test_RevertIf_AmountBelowFee() public {
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorFundingRequestAmountBelowFee.selector
            )
        );
        moneroswap.createFundingRequest(ADDR_1.balance + 1, ADDR_1.balance + 2);
    }

    function test_RevertWhen_FeeBelowMinimum() public {

        uint256 FundingRequestMinFeeRatio = vm.randomUint() % Utils.RATIO_DENOMINATOR;
        vm.prank(msg.sender);
        moneroswap.setParameters(0, FundingRequestMinFeeRatio, 0, 0, 0, 0, 0, 0, 0, Utils.MINIMUM_DELAY, Utils.MINIMUM_DELAY);
        
        vm.deal(ADDR_1, 1 ether);
        vm.prank(ADDR_1);
        uint256 fee = ((ADDR_1.balance + 1) * FundingRequestMinFeeRatio / Utils.RATIO_DENOMINATOR) - 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorFundingRequestFeeBelowMinimumRatio.selector,
                FundingRequestMinFeeRatio                
            )
        );
        moneroswap.createFundingRequest(ADDR_1.balance + 1, fee);
    }

    function testFunding_RevertWith_IncorrectAmount() public {
        uint256 amount = 100 ether;
        vm.deal(ADDR_1, 10 ether);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(amount, 1);
        vm.deal(ADDR_2, amount - 1);
        vm.prank(ADDR_2);
        vm.expectRevert(
            abi.encodeWithSelector(
                MoneroSwap.ErrorFundingRequestIncorrectAmount.selector,
                amount - 1,
                amount
            )
        );
        moneroswap.fundFundingRequest{value: amount - 1}(ADDR_1);
    }

    function testCreateFundingRequest() public {
        vm.prank(tx.origin);
        vm.expectEmit(true, true, true, true);
        emit MoneroSwap.FundingEvent(tx.origin, msg.sender.balance + 1, 1);
        moneroswap.createFundingRequest(msg.sender.balance + 1, 1);
        MoneroSwap.FundingRequest memory fundingRequest = moneroswap.getFundingRequest(tx.origin);
        assertEq(fundingRequest.amount, msg.sender.balance + 1);
        assertEq(fundingRequest.requester, tx.origin);
        assertEq(fundingRequest.fee, 1);
    }

}