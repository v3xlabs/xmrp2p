import {
    deriveEvmAccountFromRootSeed,
    deriveMoneroHotWalletSeed,
} from "xmrp2p";

import { appConfig } from "./config.js";

const loopDelayMs = appConfig.LOOP_DELAY * 1000;

const evmAccount0 = deriveEvmAccountFromRootSeed({
    rootSeed: appConfig.ROOT_SEED,
    accountIndex: 0,
});

const moneroHotWallet = deriveMoneroHotWalletSeed({
    rootSeed: appConfig.ROOT_SEED,
});

const runBotTick = (): void => {
    const now = new Date().toISOString();

    console.log(`[${now}] bot tick`);
    console.log(`contract=${appConfig.CONTRACT}`);
    console.log(`rpc=${appConfig.RPC.join(", ")}`);
    console.log(`xmr-range=${appConfig.MINXMR}..${appConfig.MAXXMR}`);
    console.log(`price-range=${appConfig.MINPRICE}..${appConfig.MAXPRICE}`);
    console.log(`evm-account[0]=${evmAccount0.address} (${evmAccount0.path})`);
    console.log(`monero-hot-wallet-path=${moneroHotWallet.path}`);
};

const start = (): void => {
    console.log("Starting xmrp2p bot with validated env config.");
    console.log("Derived keys:");
    console.log(`evm-account[0]-path=${evmAccount0.path}`);
    console.log(`evm-account[0]-address=${evmAccount0.address}`);
    console.log(`evm-account[0]-private-key=${evmAccount0.privateKey}`);
    console.log(`monero-hot-wallet-path=${moneroHotWallet.path}`);
    console.log(`monero-hot-wallet-private-key=${moneroHotWallet.privateKey}`);
    console.log(`monero-hot-wallet-seed-hex=${moneroHotWallet.seed}`);

    runBotTick();

    setInterval(runBotTick, loopDelayMs);
};

start();
