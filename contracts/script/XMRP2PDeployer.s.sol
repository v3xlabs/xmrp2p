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

        XMRP2P xmrp2p = new XMRP2P{value: VALUE}(XMRP2P.Parameters({
            MINIMUM_OFFER: 0.00001 ether,
            MAXIMUM_OFFER: 10 ether,
            DEPOSIT_RATIO: 1000, // 1000 = 10%
            MAXIMUM_OFFER_BOOK_SIZE: 100,
            T0_DELAY: 24 hours,
            T1_DELAY: 24 hours
        }), OWNER);
        console.log("Contract address: ", address(xmrp2p));

        vm.stopBroadcast();
    }
}
