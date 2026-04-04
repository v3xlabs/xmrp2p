build:
	cd contracts && forge build --silent && jq '.abi' ./out/MoneroSwap.sol/MoneroSwap.json | { printf "export const ABI = "; cat; printf " as const;\n"; } > ../lib/src/abi.ts

deploy:
	cd contracts && forge script MoneroSwapDeployer --broadcast --slow --rpc-url localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 && cd ../lib && pnpm buy
