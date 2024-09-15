## About
**DeFi StableCoin** 

The Decentralized Stablecoin () project is a secure, trustless, and permissionless stablecoin protocol designed to maintain a stable value while being backed by a pool of decentralized collateral. Unlike traditional stablecoins,  is not reliant on fiat reserves but is instead backed by over-collateralized assets like Ethereum.

This project is consist of 2 contracts. 
   1. Decentralized Stable Coin (ERC20) - Like any other Fungible Token (Crypto Token).
   2. A protocol to manage the stability of (Token). To keeping the token value maintain with the help of collateral.

**Key Components**
- ** (Decentralized Stablecoin): A fully decentralized stablecoin pegged to a stable value (e.g., USD) and backed by crypto collateral (wETH, wBTC).

- *DSCEngine*: The core smart contract that manages the issuance, redemption, and liquidation of  tokens. It ensures the system remains solvent by enforcing collateralization ratios, handling liquidation events, and enabling users to mint  by locking up collateral.

**Project Overview**
1. *Stablecoin Pegged to $1.00*
   - The stablecoin is anchored to maintain a $1.00 value, using real-time price feeds from Chainlink to track ETH and BTC market prices.  
   - Users can exchange their ETH and BTC for stablecoins, ensuring a seamless conversion process.

2. *Algorithmic Minting Mechanism*  
   - The system use an algorithmic approach to minting, ensuring decentralization.  
   - Users must provide sufficient collateral (wETH or wBTC) to mint new stablecoins, maintaining the stability of the system by ensuring the total collateral value always exceeds the minted stablecoins' value.

3. *Crypto Collateral (Exogenous)*  
   - The stablecoin is backed by exogenous assets, specifically wrapped Ethereum (wETH) and wrapped Bitcoin (wBTC).  
   - This ensures that the system leverages well-established cryptocurrencies, enhancing trust and stability while reducing volatility risks associated with other assets.


**Collateral Used**
- *wETH (Wrapped Ether)*: wETH is an ERC-20 token that represents Ether (ETH) on the Ethereum blockchain. Since ETH itself does not conform to the ERC-20 standard, wETH is created to allow ETH to be used within decentralized finance (DeFi) applications and smart contracts that require ERC-20 tokens. Users can easily wrap and unwrap ETH to wETH at a 1:1 ratio.

- *wBTC (Wrapped Bitcoin)*: wBTC is an ERC-20 token that represents Bitcoin (BTC) on the Ethereum blockchain. By wrapping BTC, users can bring the liquidity and value of Bitcoin into the Ethereum ecosystem, enabling them to participate in DeFi protocols. Each wBTC is backed 1:1 by actual Bitcoin, held in a reserve by custodians.


Here’s a clearer explanation of your liquidation mechanics with a worked example:

**Key Concepts:**
- *Threshold*: This is the minimum collateralization ratio, set to *200%* in this case. It means the value of your collateral must be at least *twice* the amount of  you've minted.
- *Collateral*: This is the asset (e.g., ETH) you're putting up to mint .
- **: The debt you’ve minted (like a loan against your collateral).
- *Liquidation*: If the value of your collateral drops below the threshold, someone can pay off your  and claim your collateral at a discount.

---

**Basic Scenario:**

1. *Threshold = 200%*
    - This means: You need *$200 worth of collateral* for every *$100 of *.
   
2. *Collateral & Minting*:
    - You deposit *$100 worth of ETH*.
    - You mint *$50 *.
    - At this point, you're collateralized at *200%* because:
        \[
        \frac{\text{Collateral}}{\text{Minted }} = \frac{100}{50} = 200\%
        \]
    - This is safe because your collateral value is above the required threshold.

---

**Liquidation Scenario:**

3. *Price Drop*:
    - The value of your collateral drops from *$100 ETH* to *$90 ETH*.
    - Now, your collateralization ratio is:
        \[
        \frac{90}{50} = 180\%
        \]
    - This is *below the 200% threshold*, meaning your position is *undercollateralized* and open to liquidation.

4. **Liquidation**:
    - Someone (the liquidator) sees that your position is undercollateralized.
    - They can pay back the *$50 * that you minted.
    - In return, they will receive:
        - *ETH in worth of $50   (equal to your  debt)*.
        - *10% bonus in collateral* as a reward for liquidating (incentive).
        - So, they get a total of *$55 DSC worth of ETH* (since $5 is the 10% bonus).

---

**Worked Example**

- *Before Liquidation*:
    - You hold *$90 ETH* as collateral.
    - You owe *$50*.

- **After Liquidation**:
    - The liquidator pays *$50 DSC*.
    - The liquidator gets:
        - *$50 DSC worth of ETH* (equal to the debt).
        - *An extra 10% of your collateral* as a bonus.
        - *Total received* = *$55 DSC worth of ETH*.

- *You* lose:
    - Your collateral of *$90 ETH*.
    - The liquidator walks away with *$55 ETH*, leaving you with only *$35 ETH* (since you were undercollateralized).

---


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application developmtten in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/



   
   
    Set a Threshold, to let say 200% 
    $100 ETH -> $50 
    IF a user get liquidated, the user shouldn't be allowed to hold the position (collateral <= ) 
    It's always be (collateral > )
    if someone pay back your minted , they can have all of your collateral in discount.
    $50  -> $90 ETH
    if you are under the threshold, someone can liquidate your position and enjoy your extra collateral as an reward.

    Example
    threshold = 200%
    $100 ETH collateral -> $90 (Value fall)
    $50  minted 
    UNDERCOLLATERIZED!!!

    SOMEBODY - I'll pay $50  to get extra 10%(bonus) of your collateral



    What are our invariants/properties?
    1. The total supply of the  should be less than the total value of collateral

    2. Getter view function should never revert <- evergreen Invarian


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
