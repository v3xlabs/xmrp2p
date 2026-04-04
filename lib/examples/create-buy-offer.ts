import { Mnemonic, Provider, Value } from "ox";
import { fromPublicKey } from "ox/Address";
import { toBigInt } from "ox/Hex";
import { fromHttp } from "ox/RpcTransport";
import { getPublicKey } from "ox/Secp256k1";

import { createBuyOfferParameters } from "../src/index.ts";
import { deriveMoneroKeys } from "../src/monero/keys.ts";
import { sendTransaction } from "../src/tx.ts";

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

const mnemonic = Mnemonic.random(Mnemonic.english);

const { publicViewKey, publicSpendKey } = deriveMoneroKeys({
    rootSeed: mnemonic,
});

const buyOfferParams = createBuyOfferParameters({
    counterparty,
    contractAddress: MONERO_SWAP_ADDRESS,
    price: xmrPriceInEth,
    minxmr: minXmr,
    publicspendkey: toBigInt(publicSpendKey),
    publicviewkey: toBigInt(publicViewKey),
});

const hash = await sendTransaction({
    from: offerCreator,
    privateKey: offerCreatorPk,
    provider,
    chainId: 31_337,
    value: Value.fromEther("2"),
    ...buyOfferParams,
});

console.log(hash);
