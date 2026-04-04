import { sha512 } from "@noble/hashes/sha2.js";
import { Address, Hex, Mnemonic, Secp256k1 } from "ox";

const derivePrivateKeyAtPath = ({
    rootSeed,
    path,
}: {
    rootSeed: string;
    path: string;
}): Hex.Hex =>
    Mnemonic.toPrivateKey(rootSeed, {
        as: "Hex",
        path,
    });

const leastSignificantBytes = (value: Uint8Array, size: number): Uint8Array =>
    value.slice(Math.max(0, value.length - size));

export const deriveEvmAccountFromRootSeed = ({
    rootSeed,
    accountIndex,
}: {
    rootSeed: string;
    accountIndex: number;
}): {
    address: Address.Address;
    privateKey: Hex.Hex;
    path: string;
} => {
    const path = `m/44'/60'/${accountIndex}'/0/0`;
    const privateKey = derivePrivateKeyAtPath({
        path,
        rootSeed,
    });
    const publicKey = Secp256k1.getPublicKey({ privateKey });
    const address = Address.fromPublicKey(publicKey, { checksum: true });

    return {
        address,
        path,
        privateKey,
    };
};

export const deriveMoneroHotWalletSeed = ({
    rootSeed,
}: {
    rootSeed: string;
}): {
    path: string;
    privateKey: Hex.Hex;
    seed: Hex.Hex;
} => {
    const path = "m/44'/128'/0'/0/0";
    const privateKey = derivePrivateKeyAtPath({
        path,
        rootSeed,
    });
    const hash = sha512(Hex.toBytes(privateKey));
    const seed = Hex.fromBytes(leastSignificantBytes(hash, 32));

    return {
        path,
        privateKey,
        seed,
    };
};
