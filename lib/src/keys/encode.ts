import { hexToBytes } from "@noble/hashes/utils.js";
import { keccak256 } from "ox/Hash";

import { base58encode } from "../utils/base58";

const MONERO_MAINNET_HEX_PREFIX = "12";
const MONERO_STAGENET_HEX_PREFIX = "18";

export const encodeMoneroAddress = (publicSpendKey: bigint, publicViewKey: bigint, xmrMainnnet: boolean) => {
    let hex = xmrMainnnet ? MONERO_MAINNET_HEX_PREFIX : MONERO_STAGENET_HEX_PREFIX;

    hex += publicSpendKey.toString(16).padStart(64, "0");
    hex += publicViewKey.toString(16).padStart(64, "0");

    // Compute keccak of 'bytes' to add the checksum to the address
    const k = keccak256(hexToBytes("0x" + hex));

    hex += k.slice(2, 10);

    const bytes = hexToBytes("0x" + hex);
    let offset = 0;
    let addr = "";

    while (offset < bytes.length) {
        const blockbytes = bytes.slice(offset, offset + 8);
        let block = base58encode(blockbytes);

        // pad blocks if not padded
        if (blockbytes.length == 8) {
            while (block.length < 11) {
                block = "1" + block;
            }
        }
        else if (blockbytes.length == 5) {
            while (block.length < 7) {
                block = "1" + block;
            }
        }

        addr = addr + block;
        offset = offset + 8;
    }

    return addr;
};
