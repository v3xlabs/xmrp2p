build:
  # appends the abi directly with " as const;" no newlines
  cd contracts && forge build --silent && jq -c '.abi' ./out/XMRP2P.sol/XMRP2P.json \
  | sed 's/^/export const ABI = /' \
  | sed 's/$$/ as const;/' \
  > ../lib/src/abi.ts

deploy:
  cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x225f137127d9067788314bc7fcc1f36746a3c3B5 --value 1000000000000000000
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x6bf9Ea00A82797bCB5c94ba86fA3f68f6dB090a6 --value 1000000000000000000

# via frame
deploy-sepolia:
  cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url https://sepolia.drpc.org --account deployer

verify-sepolia:
	cd contracts && forge verify-contract 0xAd6871D44804288ba4393464C63544d6691D76BA src/XMRP2P.sol:XMRP2P --chain sepolia --constructor-args 0x225f137127d9067788314bc7fcc1f36746a3c3B5

test:
  cd contracts && forge test

lint:
  cd contracts && forge fmt
  cd web && pnpm eslint --fix

cov:
  cd contracts && forge test --gas-report --match-path "tests/solidity/XMRP2P*" && forge snapshot
