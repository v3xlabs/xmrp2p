build:

	# appends the abi directly with " as const;" no newlines
	cd contracts && forge build --silent && jq -c '.abi' ./out/XMRP2P.sol/XMRP2P.json \
	| sed 's/^/export const ABI = /' \
	| sed 's/$$/ as const;/' \
	> ../lib/src/abi.ts

deploy:
	cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
