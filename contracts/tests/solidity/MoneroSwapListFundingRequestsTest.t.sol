// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapListFundingRequestsTest is Test {

    address ADDR_1 = address(0x1111111111111111111111111111111111111111);
    
    function testListFundingRequests() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);

        uint256 N = 7;

        // Create N funding requests
        for (uint160 i = 1; i <= N; i++) {
            vm.deal(address(uint160(10000000000000000000000000000000000000000 + i)), 1 ether - 1 wei);
            vm.prank(address(uint160(10000000000000000000000000000000000000000 + i)));
            moneroswap.createFundingRequest(i * 1 ether, i);
        }

        // List buy offers by chunks of 2 with a step of 3
        for (uint160 i = 0; i < N + 4; i += 3) {
            MoneroSwap.FundingRequest[] memory requests = moneroswap.listFundingRequests(i, 2);
           
            if (requests.length >= 1) {
                assertEq(requests[0].amount, (i + 1) * 1 ether);
                assertEq(requests[0].fee, i + 1);
                assertEq(requests[0].index, i);
            }
            if (requests.length >= 2) {
                assertEq(requests[1].amount, (i + 2) * 1 ether);
                assertEq(requests[1].fee, i + 2);
                assertEq(requests[1].index, i + 1);
            }
        }
    }
}