// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Ed25519} from "../../src/Ed25519.sol";

/// Tests for the Ed25519 library
contract Ed25519Test is Test {

    function setUp() public {
    }

    function testChangeEndianness() public pure {
        uint256 be = 0xebb84529f27fe2b7dde8bfadafcb3e07e0b43510ef2b20746effe5962ff33d02;
        uint256 le = Ed25519.changeEndianness(be);
        assertEq(0x023df32f96e5ff6e74202bef1035b4e0073ecbafadbfe8ddb7e27ff22945b8eb, le);
        uint256 x = Ed25519.changeEndianness(le);
        assertEq(x, be);
    }

    function testScalarMultBase() public view {
        uint256 PRIVATE_1 = 0xebb84529f27fe2b7dde8bfadafcb3e07e0b43510ef2b20746effe5962ff33d02;
        uint256 PUBLIC_1  = 0xf073e0ad5cfbc29d6efb479af0cb8fd8032fc3279232d3234821dc73be8f83e7; // LE
        uint256 PRIVATE_2 = 0x3c27472aaaf62fcea2ef1e0f1ff031d5fcec66c60275c793453f93f5387fa207;
        uint256 PUBLIC_2  = 0x147903d70be6476a41ceb934825478be96d4e3d4ae186a6808ac9cc77b840709; // LE

        (uint256 x, uint256 y) = Ed25519.scalarMultBase(Ed25519.changeEndianness(PRIVATE_1)); // Returns Big Endian
        uint256 pub1 = Ed25519.changeEndianness(Ed25519.compressPoint(x,y)); // BE to LE
        assertEq(PUBLIC_1, pub1);

        (x, y) = Ed25519.scalarMultBase(Ed25519.changeEndianness(PRIVATE_2));
        uint256 pub2 = Ed25519.changeEndianness(Ed25519.compressPoint(x,y)); // BE to LE
        assertEq(PUBLIC_2, pub2);
    }
}
