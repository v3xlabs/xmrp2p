import { Provider, Value } from "ox";
import { fromPublicKey } from "ox/Address";
import { fromHttp } from "ox/RpcTransport";
import { getPublicKey } from "ox/Secp256k1";

import { createBuyOfferParameters } from "../src/index.ts";
import { sendTransaction } from "../src/tx.ts";

const provider = Provider.from(fromHttp("http://localhost:8545"));

const offerCreatorPk =
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

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
const minXmr = Value.fromEther("0.01"); // 0.01 XMR in piconeros

const buyOfferParams = createBuyOfferParameters({
  counterparty,
  contractAddress: MONERO_SWAP_ADDRESS,
  price: xmrPriceInEth,
  minxmr: minXmr,
  publicspendkey: 12345678901234567890123456789012345678901234567890123456789012345n,
  publicviewkey: 98765432109876543210987654321098765432109876543210987654321098765n,
  msgpubkey: 11111111111111111111111111111111111111111111111111111111111111111n,
});

const hash = await sendTransaction({
  from: offerCreator,
  privateKey: offerCreatorPk,
  provider,
  chainId: 31_337,
  value: Value.fromEther("1"),
  ...buyOfferParams,
});
