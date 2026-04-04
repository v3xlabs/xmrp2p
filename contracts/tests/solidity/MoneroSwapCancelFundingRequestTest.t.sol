// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import "../../src/Errors.sol";
import "../../src/Errors.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapCancelFundingRequestTest is Test {
    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    address ADDR_2 = address(0x2222222222222222222222222222222222222222);

    function test_RevertWhen_CurrentlyFunded() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 1 ether - 1);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        vm.deal(ADDR_2, 1 ether);
        vm.prank(ADDR_2);
        moneroswap.fundFundingRequest{value: 1 ether}(ADDR_1);

        vm.prank(ADDR_1);
        vm.expectRevert(ErrorFundingRequestCurrentlyFunded.selector);
        moneroswap.cancelFundingRequest();
    }

    function testCancelFundingRequest() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        vm.deal(ADDR_1, 1 ether - 1);
        vm.prank(ADDR_1);
        moneroswap.createFundingRequest(1 ether, 0);

        vm.prank(ADDR_1);
        moneroswap.cancelFundingRequest();

        vm.expectRevert(ErrorFundingRequestNotFound.selector);
        moneroswap.getFundingRequest(ADDR_1);

        assertEq(0, moneroswap.listFundingRequests(0, 1).length);
    }
}
