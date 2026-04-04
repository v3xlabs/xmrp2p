import { sha512 } from "@noble/hashes/sha2.js";
import { keccak_256 } from "@noble/hashes/sha3.js";
import { Ed25519, Hex } from "ox";

// ed25519 subgroup order
const L = BigInt(
  "0x1000000000000000000000000000000014DEF9DEA2F79CD65812631A5CF5D3ED",
);

function sc_reduce32(bytes: Uint8Array): Uint8Array {
  const hexString = Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  const num = BigInt("0x" + hexString);
  const reduced = num % L;

  const reducedHex = reduced.toString(16).padStart(64, "0");
  const reducedBytes = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    reducedBytes[i] = parseInt(reducedHex.slice(i * 2, i * 2 + 2), 16);
  }
  return reducedBytes;
}

export const deriveMoneroKeys = ({ rootSeed }: { rootSeed: string }) => {
  const encoder = new TextEncoder();
  const seedFull = sha512(encoder.encode(rootSeed));
  const seed = seedFull.slice(0, 32);

  const privateSpendKeyBytes = sc_reduce32(seed);
  const privateViewKeyBytes = sc_reduce32(keccak_256(privateSpendKeyBytes));

  const privateSpendKey = Hex.fromBytes(privateSpendKeyBytes);
  const privateViewKey = Hex.fromBytes(privateViewKeyBytes);

  const publicSpendKey = Ed25519.getPublicKey({
    privateKey: privateSpendKey,
  });

  const publicViewKey = Ed25519.getPublicKey({
    privateKey: privateViewKey,
  });

  return {
    privateSpendKey,
    privateViewKey,
    publicSpendKey,
    publicViewKey,
  };
};
