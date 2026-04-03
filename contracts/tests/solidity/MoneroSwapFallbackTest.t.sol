// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapFallbackTest is Test {    
    function testFallback() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        (bool res, bytes memory revertData) = payable(address(moneroswap)).call{value: 1 ether}("test");
        require(!res);
        assertEq(revertData, abi.encodeWithSelector(MoneroSwap.ErrorUnableToAcceptPayment.selector));
    }
}