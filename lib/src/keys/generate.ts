import { Point } from "@noble/ed25519";
import { keccak256 } from "ox/Hash";
import { bytesToBigInt, hexToBytes } from "viem";
import { mnemonicToAccount } from "viem/accounts";

const ED25519_L = 2n ** 252n + 27_742_317_777_372_353_535_851_937_790_883_648_493n;
const SPEND_KEY_PATH = "m/44'/128'/0'/0/0";

export const generateMoneroKeys = (seedphrase: string) => {
    seedphrase = seedphrase.trim();

    //
    // Generate private spend and message keys
    //
    const privateSpendKey = bytesToBigInt(mnemonicToAccount(seedphrase, { path: SPEND_KEY_PATH as never }).getHdKey().privateKey as Uint8Array) % ED25519_L;

    //
    // Derive private view key from private spend key
    //

    const privateSpendKeyHex = privateSpendKey.toString(16).padStart(64, "0");
    const bytes = hexToBytes(`0x${privateSpendKeyHex}`);

    // Use little endian representation
    bytes.reverse();

    const privateViewKey = bytesToBigInt(keccak256(bytes, { as: "Bytes" }).reverse()) % ED25519_L;

    const publicSpendKey: Point = Point.BASE.multiply(privateSpendKey, true);
    const publicViewKey: Point = Point.BASE.multiply(privateViewKey, true);

    return {
        privateSpendKey,
        publicSpendKey: bytesToBigInt(publicSpendKey.toBytes()),
        privateViewKey,
        publicViewKey: bytesToBigInt(publicViewKey.toBytes()),
    };
};
