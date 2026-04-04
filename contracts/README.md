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
forge script MoneroSwapDeployer --broadcast --slow
forge script MoneroSwapRelayOracleDeployer --broadcast --slow
```
