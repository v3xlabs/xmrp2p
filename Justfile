build:
  # appends the abi directly with " as const;" no newlines
  cd contracts && forge build --silent && jq -c '.abi' ./out/XMRP2P.sol/XMRP2P.json | sed 's/^/export const ABI = /; s/$/ as const;/' > ../lib/src/abi.ts

deploy:
  cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x225f137127d9067788314bc7fcc1f36746a3c3B5 --value 1000000000000000000
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x6bf9Ea00A82797bCB5c94ba86fA3f68f6dB090a6 --value 1000000000000000000

# via frame
deploy-sepolia:
  cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url https://sepolia.drpc.org --account deployer

verify-sepolia:
	cd contracts && forge verify-contract 0x24be36Db392A8c69E9336A5Fdb53fFB6c978CDA8 src/XMRP2P.sol:XMRP2P --verifier etherscan --chain sepolia --constructor-args $(cast abi-encode "constructor((uint256,uint256,uint256,uint256,uint256,uint256),address)" "(10000000000000,10000000000000000000,500,100,86400,86400)" "0x225f137127d9067788314bc7fcc1f36746a3c3B5")
	cd contracts && forge verify-contract 0x24be36Db392A8c69E9336A5Fdb53fFB6c978CDA8 src/XMRP2P.sol:XMRP2P --verifier sourcify --chain sepolia --constructor-args $(cast abi-encode "constructor((uint256,uint256,uint256,uint256,uint256,uint256),address)" "(10000000000000,10000000000000000000,500,100,86400,86400)" "0x225f137127d9067788314bc7fcc1f36746a3c3B5")

# via frame
deploy-mainnet:
  cd contracts && forge script XMRP2PDeployer --broadcast --slow --rpc-url https://ethereum.reth.rs/rpc --account deployer

verify-mainnet:
	cd contracts && forge verify-contract 0xAd6871D44804288ba4393464C63544d6691D76BA src/XMRP2P.sol:XMRP2P --verifier etherscan --chain mainnet --constructor-args $(cast abi-encode "constructor((uint256,uint256,uint256,uint256,uint256,uint256),address)" "(10000000000000,10000000000000000000,500,100,86400,86400)" "0x225f137127d9067788314bc7fcc1f36746a3c3B5")
	cd contracts && forge verify-contract 0xAd6871D44804288ba4393464C63544d6691D76BA src/XMRP2P.sol:XMRP2P --verifier sourcify --chain mainnet --constructor-args $(cast abi-encode "constructor((uint256,uint256,uint256,uint256,uint256,uint256),address)" "(10000000000000,10000000000000000000,500,100,86400,86400)" "0x225f137127d9067788314bc7fcc1f36746a3c3B5")

test:
  cd contracts && forge test

lint: build
  cd contracts && forge fmt
  cd web && pnpm eslint --fix

cov:
  cd contracts && forge test --gas-report --match-path "tests/solidity/XMRP2P*" && forge snapshot
