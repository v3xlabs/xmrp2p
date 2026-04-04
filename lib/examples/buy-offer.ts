import { Ed25519, Mnemonic, Provider, Value } from "ox";
import { fromPublicKey } from "ox/Address";
import { fromBytes, toBigInt } from "ox/Hex";
import { fromHttp } from "ox/RpcTransport";
import { getPublicKey } from "ox/Secp256k1";

import {
    claimParameters,
    createBuyOfferParameters,
    getBuyOffer,
    readyParameters,
    takeBuyOfferParameters,
} from "../src/index.ts";
import { deriveMoneroKeys } from "../src/monero/keys.ts";
import { sendTransaction, waitForTransaction } from "../src/tx.ts";

// Derive the contract-compatible public key from a private key scalar.
// The contract uses raw Ed25519 scalar multiplication (no clamping/hashing),
// then stores changeEndianness(compressPoint(x,y)).
function contractPublicKey(privateKeyHex: `0x${string}`): bigint {
    const scalar = BigInt(privateKeyHex);
    const point = Ed25519.noble.ExtendedPoint.BASE.multiply(scalar);
    const compressed = point.toRawBytes(); // little-endian compressed

    return toBigInt(fromBytes(compressed));
}

const provider = Provider.from(fromHttp("http://localhost:8545"));

const offerCreatorPk
  = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const MONERO_SWAP_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

const offerCreator = fromPublicKey(
    getPublicKey({
        privateKey: offerCreatorPk,
    }),
);

const counterparty = fromPublicKey(
    getPublicKey({
        privateKey:
      "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
    }),
);

const xmrPriceInEth = Value.fromEther("0.1");
const minXmr = Value.from("0.01", 12); // 0.01 XMR in piconeros

// Maker's Monero keys
const mnemonic = Mnemonic.random(Mnemonic.english);

const makerKeys = deriveMoneroKeys({
    rootSeed: mnemonic,
});

// Step 1: Create buy offer (maker deposits ETH)
const buyOfferParams = createBuyOfferParameters({
    counterparty,
    contractAddress: MONERO_SWAP_ADDRESS,
    price: xmrPriceInEth,
    minxmr: minXmr,
    publicspendkey: contractPublicKey(makerKeys.privateSpendKey),
    publicviewkey: contractPublicKey(makerKeys.privateViewKey),
});

const hash = await sendTransaction({
    from: offerCreator,
    privateKey: offerCreatorPk,
    provider,
    chainId: 31_337,
    value: Value.fromEther("2"),
    ...buyOfferParams,
});

const createReceipt = await waitForTransaction(provider, hash);

console.log("Buy offer created:", createReceipt.transactionHash);

// Step 2: Get the offer ID from the creation receipt logs
const offerId = toBigInt(createReceipt.logs[0].data);

console.log("Offer ID:", offerId.toString());

const offer = await getBuyOffer({
    provider,
    contractAddress: MONERO_SWAP_ADDRESS,
    id: offerId,
});

// Step 3: Generate taker's Monero keys
const takerMnemonic = Mnemonic.random(Mnemonic.english);
const takerKeys = deriveMoneroKeys({ rootSeed: takerMnemonic });

console.log("Taker public spend key:", takerKeys.publicSpendKey);
console.log("Taker public view key:", takerKeys.publicViewKey);

// Step 4: Taker takes the buy offer
const takerPk
  = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";

const takeHash = await sendTransaction({
    from: counterparty,
    privateKey: takerPk,
    provider,
    chainId: 31_337,
    value: Value.fromEther("0.1"),
    ...takeBuyOfferParameters({
        contractAddress: MONERO_SWAP_ADDRESS,
        id: offer.id,
        maxxmr: Value.from("0.1", 12), // 0.1 XMR in piconeros
        minprice: xmrPriceInEth,
        publicspendkey: contractPublicKey(takerKeys.privateSpendKey),
        privateviewkey: toBigInt(takerKeys.privateViewKey),
    }),
});

await waitForTransaction(provider, takeHash);
console.log("Buy offer taken:", takeHash);

// Step 5: Maker calls ready() - confirms XMR receipt
const readyHash = await sendTransaction({
    from: offerCreator,
    privateKey: offerCreatorPk,
    provider,
    chainId: 31_337,
    ...readyParameters({
        contractAddress: MONERO_SWAP_ADDRESS,
        id: offer.id,
    }),
});

await waitForTransaction(provider, readyHash);
console.log("Offer ready:", readyHash);

// Step 6: Taker calls claim() - reveals private spend key to claim ETH
const claimHash = await sendTransaction({
    from: counterparty,
    privateKey: takerPk,
    provider,
    chainId: 31_337,
    ...claimParameters({
        contractAddress: MONERO_SWAP_ADDRESS,
        id: offer.id,
        privateSpendKey: toBigInt(takerKeys.privateSpendKey),
    }),
});

await waitForTransaction(provider, claimHash);
console.log("Offer claimed - swap complete:", claimHash);

// Log the taker's revealed private spend key so maker can recover XMR
console.log("\n=== Swap Complete ===");
console.log("Taker's private spend key (for XMR recovery):", takerKeys.privateSpendKey);
console.log("Taker's private view key (for XMR recovery):", takerKeys.privateViewKey);
console.log("Maker can now recover XMR using these keys");
