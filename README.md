## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage
1. Relative Stability: Anchored or Pegged -> $1.00
   1. Chainlink Price feed.
   2. Set a function to exchange ETH & BTC -> $$$$
2. Stability Mechanism (Minting): Algorithm (Decentralized)
   1. People can only ming the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
   1. wETH
   2. wBTC
   
   
    Set a Threshold, to let say 150% 
    $100 ETH -> 75$ ETH
    $50 DSC
    IF a user get liquidated, the user shouldn't be allowed to hold the position (collateral <= DSC) 
    It's always be (collateral > DSC)
    if someone pay back your minted DSC, they can have all of your collateral in discount.
    $50 DSC -> $74 ETH
    if you are under the threshold, someone can liquidate your position and enjoy your extra collateral as an reward.

    Example
    threshold = 150%
    $100 ETH collateral -> $74 (Value fall)
    $50 DSC minted 
    UNDERCOLLATERIZED!!!

    SOMEBODY - I'll pay $50 DSC to get $74 ETH (your collateral)


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
