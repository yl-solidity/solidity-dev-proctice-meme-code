## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

````
forge build
forge script script/DeployLiquidity.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --broadcast -vvvv
````
````
== Logs ==
  Deployer address: 0xCC2B75Acee22512ff1Fddf440877417370D0eCA4
  Adding Router and Factory to exemption lists...
  Creating new pair...
  Pair created at: 0x2F75f73F8beEaFa8a35aE8FA8ed644D4e3C90324
  Approving tokens...
  Adding liquidity...
  Liquidity added successfully
  Pair address: 0x2F75f73F8beEaFa8a35aE8FA8ed644D4e3C90324

````