// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Ed25519} from "../../src/Ed25519.sol";
import {XMRP2P} from "../../src/XMRP2P.sol";
import {Offer, FundingRequest} from "../../src/Structs.sol";
import {OfferType, OfferState} from "../../src/Enums.sol";
import "../../src/Errors.sol";

library Utils {
    uint256 constant UNITS_PER_XMR = 1_000_000_000_000;
    uint256 constant ED25519_L = 2 ** 252 + 27742317777372353535851937790883648493;
    uint256 constant LIABILITY_BUFFER = 4;
    uint256 constant RATIO_DENOMINATOR = 1_000_000_000;
    uint256 constant MINIMUM_DELAY = 24 hours;

    /// Generate random offer keys for both the EVM and XMR sides of a swap
    function generateOfferKeys(VmSafe vm)
        public
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        // Generate private view/spend keys
        uint256 evmPrivateViewKey = vm.randomUint() % ED25519_L;
        uint256 evmPrivateSpendKey = vm.randomUint() % ED25519_L;
        uint256 xmrPrivateViewKey = vm.randomUint() % ED25519_L;
        uint256 xmrPrivateSpendKey = vm.randomUint() % ED25519_L;

        // Compute the public keys
        (uint256 x, uint256 y) = Ed25519.scalarMultBase(evmPrivateSpendKey);
        uint256 evmPublicSpendKey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));
        (x, y) = Ed25519.scalarMultBase(evmPrivateViewKey);
        uint256 evmPublicViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));

        (x, y) = Ed25519.scalarMultBase(xmrPrivateSpendKey);
        uint256 xmrPublicSpendKey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));
        (x, y) = Ed25519.scalarMultBase(xmrPrivateViewKey);
        uint256 xmrPublicViewKey = Ed25519.changeEndianness(Ed25519.compressPoint(x, y));

        return (
            evmPrivateViewKey,
            evmPrivateSpendKey,
            evmPublicViewKey,
            evmPublicSpendKey,
            xmrPrivateViewKey,
            xmrPrivateSpendKey,
            xmrPublicViewKey,
            xmrPublicSpendKey
        );
    }

    function checkLiability(address addr) public view {
        MoneroSwap moneroswap = MoneroSwap(payable(addr));
        uint256 liability = moneroswap.getLiability();
        uint256 contractBalance = address(moneroswap).balance;

        console.log("Contract   ", contractBalance);
        console.log("liability  ", liability);
        console.log("Available  ", contractBalance - liability);
        console.log("");
        // Liability should always be less than the total contract balance
        assert(liability <= contractBalance);
    }
}
