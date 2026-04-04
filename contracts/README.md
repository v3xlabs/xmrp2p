# Contracts

## Build

```sh
forge build
```

## Deploy locally

Start Anvil:

```sh
anvil
```

Deploy contracts:

```sh
forge script MoneroSwapDeployer --broadcast --slow --rpc-url localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## TODO

- add ownable back
- buyOffers & sellOffers
