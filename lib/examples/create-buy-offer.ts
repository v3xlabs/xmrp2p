import { Ed25519, Mnemonic, Provider, Value } from "ox";
import { fromPublicKey } from "ox/Address";
import { fromBytes, toBigInt } from "ox/Hex";
import { fromHttp } from "ox/RpcTransport";
import { getPublicKey } from "ox/Secp256k1";

import {
    createBuyOfferParameters,
    getBuyOffer,
} from "../src/index.ts";
import { deriveMoneroKeys } from "../src/monero/keys.ts";
import { sendTransaction, waitForTransaction } from "../src/tx.ts";

function contractPublicKey(privateKeyHex: `0x${string}`): bigint {
    const scalar = BigInt(privateKeyHex);
    const point = Ed25519.noble.ExtendedPoint.BASE.multiply(scalar);
    const compressed = point.toRawBytes();

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

const xmrPriceInEth = Value.fromEther("0.1");
const minXmr = Value.from("0.01", 12);

const mnemonic = Mnemonic.random(Mnemonic.english);

const makerKeys = deriveMoneroKeys({
    rootSeed: mnemonic,
});

const buyOfferParams = createBuyOfferParameters({
    counterparty: "0x0000000000000000000000000000000000000000",
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

const offerId = toBigInt(createReceipt.logs[0].data);

console.log("Offer ID:", offerId.toString());

const offer = await getBuyOffer({
    provider,
    contractAddress: MONERO_SWAP_ADDRESS,
    id: offerId,
});

console.log("Offer state:", offer.state);
console.log("Offer owner:", offer.owner);
console.log("Offer maxamount:", offer.maxamount);
console.log("Offer price:", offer.price);

console.log("\n=== Maker Keys (for reference) ===");
console.log("Private spend key:", makerKeys.privateSpendKey);
console.log("Private view key:", makerKeys.privateViewKey);
console.log("Public spend key:", makerKeys.publicSpendKey);
console.log("Public view key:", makerKeys.publicViewKey);
