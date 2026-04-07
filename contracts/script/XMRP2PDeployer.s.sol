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
            MINIMUM_BUY_OFFER: 0.001 ether,
            MAXIMUM_BUY_OFFER: 100 ether,
            MINIMUM_SELL_OFFER: 0.001 ether,
            MAXIMUM_SELL_OFFER: 100 ether,
            DEPOSIT_RATIO: 1,
            MAXIMUM_OFFER_BOOK_SIZE: 100,
            MINIMUM_DELAY: 24 hours,
            T0_DELAY: 1 hours,
            T1_DELAY: 1 hours
        }));
        console.log("Contract address: ", address(xmrp2p));

        vm.stopBroadcast();
    }
}
