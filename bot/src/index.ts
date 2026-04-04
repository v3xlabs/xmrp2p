import {
    deriveEvmAccountFromRootSeed,
    deriveMoneroHotWalletSeed,
} from "xmrp2p";

import { botConfig } from "./config.js";
import { createProviderPool } from "./evmProvider.js";
import { createRunner } from "./runner.js";

const evmAccount0 = deriveEvmAccountFromRootSeed({
    rootSeed: botConfig.ROOT_SEED,
    accountIndex: 0,
});

const moneroHotWallet = deriveMoneroHotWalletSeed({
    rootSeed: botConfig.ROOT_SEED,
});

const start = (): void => {
    console.log("Starting xmrp2p bot with validated env config.");
    console.log("Derived keys:");
    console.log(`evm-account[0]-path=${evmAccount0.path}`);
    console.log(`evm-account[0]-address=${evmAccount0.address}`);
    console.log(`evm-account[0]-private-key=${evmAccount0.privateKey}`);
    console.log(`monero-hot-wallet-path=${moneroHotWallet.path}`);
    console.log(`monero-hot-wallet-private-key=${moneroHotWallet.privateKey}`);
    console.log(`monero-hot-wallet-seed-hex=${moneroHotWallet.seed}`);

    const providers = createProviderPool(botConfig.RPC);
    const runner = createRunner({
        config: botConfig,
        providers,
    });

    runner.start();
};

start();
