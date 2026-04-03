import { appConfig } from "./config.js";

const loopDelayMs = appConfig.LOOP_DELAY * 1000;

const runBotTick = (): void => {
    const now = new Date().toISOString();

    console.log(`[${now}] bot tick`);
    console.log(`contract=${appConfig.CONTRACT}`);
    console.log(`rpc=${appConfig.RPC.join(", ")}`);
    console.log(`xmr-range=${appConfig.MINXMR}..${appConfig.MAXXMR}`);
    console.log(`price-range=${appConfig.MINPRICE}..${appConfig.MAXPRICE}`);
};

const start = (): void => {
    console.log("Starting xmrp2p bot with validated env config.");

    runBotTick();

    setInterval(runBotTick, loopDelayMs);
};

start();
