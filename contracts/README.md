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

Note: For production deployment, copy the `.sol.template` files to `.sol` and update the `OWNER` address and `SALT` values.
