// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {MoneroSwapRelayOracle} from "../src/MoneroSwapRelayOracle.sol";

contract MoneroSwapRelayOracleDeployer is Script {

    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    bytes32 constant SALT = bytes32(0);

    function run() public {
        vm.startBroadcast();

        MoneroSwapRelayOracle moneroswaporacle = new MoneroSwapRelayOracle(OWNER);
        console.log("Contract address: ", address(moneroswaporacle));

        vm.stopBroadcast();
    }
}
