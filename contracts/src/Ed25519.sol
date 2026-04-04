// From https://github.com/javgh/ed25519-solidity/blob/master/contract/Ed25519.sol
//
// Copyright (c) 2019, Jan Vornberger - licensed under the MIT license
//
// converted to a library by hbs in 2025 to avoid having to deploy a specific Ed22519 contract

pragma solidity ^0.8.34;

// Using formulas from https://hyperelliptic.org/EFD/g1p/auto-twisted-projective.html
// and constants from https://tools.ietf.org/html/draft-josefsson-eddsa-ed25519-03

library Ed25519 {
    uint256 constant q = 2 ** 255 - 19;
    uint256 constant d = 37095705934669439343138083508754565189542113879843219016388785533085940283555;
    // = -(121665/121666)
    uint256 constant Bx = 15112221349535400772501151409588531511454012693041857206046113283949847762202;
    uint256 constant By = 46316835694926478169428394003475163141307993866256225615783033603165251855960;

    struct Point {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    struct Scratchpad {
        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;
        uint256 e;
        uint256 f;
        uint256 g;
        uint256 h;
    }

    function inv(uint256 a) internal view returns (uint256 invA) {
        uint256 e = q - 2;
        uint256 m = q;

        // use bigModExp precompile
        assembly {
            let p := mload(0x40)
            mstore(p, 0x20)
            mstore(add(p, 0x20), 0x20)
            mstore(add(p, 0x40), 0x20)
            mstore(add(p, 0x60), a)
            mstore(add(p, 0x80), e)
            mstore(add(p, 0xa0), m)
            if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            invA := mload(p)
        }
    }

    function ecAdd(Point memory p1, Point memory p2) internal pure returns (Point memory p3) {
        Scratchpad memory tmp;

        tmp.a = mulmod(p1.z, p2.z, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p2.x, q);
        tmp.d = mulmod(p1.y, p2.y, q);
        tmp.e = mulmod(d, mulmod(tmp.c, tmp.d, q), q);
        tmp.f = addmod(tmp.b, q - tmp.e, q);
        tmp.g = addmod(tmp.b, tmp.e, q);
        p3.x = mulmod(
            mulmod(tmp.a, tmp.f, q),
            addmod(addmod(mulmod(addmod(p1.x, p1.y, q), addmod(p2.x, p2.y, q), q), q - tmp.c, q), q - tmp.d, q),
            q
        );
        p3.y = mulmod(mulmod(tmp.a, tmp.g, q), addmod(tmp.d, tmp.c, q), q);
        p3.z = mulmod(tmp.f, tmp.g, q);
    }

    function ecDouble(Point memory p1) internal pure returns (Point memory p2) {
        Scratchpad memory tmp;

        tmp.a = addmod(p1.x, p1.y, q);
        tmp.b = mulmod(tmp.a, tmp.a, q);
        tmp.c = mulmod(p1.x, p1.x, q);
        tmp.d = mulmod(p1.y, p1.y, q);
        tmp.e = q - tmp.c;
        tmp.f = addmod(tmp.e, tmp.d, q);
        tmp.h = mulmod(p1.z, p1.z, q);
        tmp.g = addmod(tmp.f, q - mulmod(2, tmp.h, q), q);
        p2.x = mulmod(addmod(addmod(tmp.b, q - tmp.c, q), q - tmp.d, q), tmp.g, q);
        p2.y = mulmod(tmp.f, addmod(tmp.e, q - tmp.d, q), q);
        p2.z = mulmod(tmp.f, tmp.g, q);
    }

    function scalarMultBase(uint256 s) internal view returns (uint256, uint256) {
        Point memory b;
        Point memory result;
        b.x = Bx;
        b.y = By;
        b.z = 1;
        result.x = 0;
        result.y = 1;
        result.z = 1;

        while (s > 0) {
            if (s & 1 == 1) result = ecAdd(result, b);
            s = s >> 1;
            b = ecDouble(b);
        }

        uint256 invZ = inv(result.z);
        result.x = mulmod(result.x, invZ, q);
        result.y = mulmod(result.y, invZ, q);

        return (result.x, result.y);
    }

    function changeEndianness(uint256 _bigEnd) internal pure returns (uint256) {
        uint256 shifted = 0;
        uint256 i = 32;
        while (i > 0) {
            shifted <<= 8;
            shifted |= _bigEnd & 0xff;
            _bigEnd >>= 8;
            i--;
        }
        return shifted;
    }

    function compressPoint(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 compressed = y | ((x & 1) << 255);
        // Return is in Big Endian order - need to change endianness to stick to Monero's convention of using Little Endian
        return compressed;
    }
}
