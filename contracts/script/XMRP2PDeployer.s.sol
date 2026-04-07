// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {XMRP2P} from "../src/XMRP2P.sol";

contract XMRP2PDeployer is Script {
    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 constant SALT = bytes32(0);
    uint256 constant VALUE = 0;

    function run() public {
        vm.startBroadcast();

        XMRP2P xmrp2p = new XMRP2P{value: VALUE}();
        console.log("Contract address: ", address(xmrp2p));

        vm.stopBroadcast();
    }
}
