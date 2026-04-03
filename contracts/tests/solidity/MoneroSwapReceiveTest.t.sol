// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MoneroSwap} from "../../main/solidity/MoneroSwap.sol";

import {Utils} from "./Utils.t.sol";

contract MoneroSwapReceiveTest is Test {

    function testReceive() public {
        MoneroSwap moneroswap = new MoneroSwap(msg.sender);
        (bool res) = payable(address(moneroswap)).send(1 ether);
        require(!res);
    }
}