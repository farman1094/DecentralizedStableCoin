// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.18;

/**
 * @title DSCEngine
 * @author Mohd Farman
 *
 * This system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1$ peg.
 * The stablecoin has the properties:
 * - Exogenous Collateral: ETH & BTC
 * - Dollar pegged
 * - Algorithmic Stable
 *
 * It is similar to DAI if DAI had no governance, no fees and only backed by WETH and WBTC.
 *
 * @notice The contract is the core of the DSC System. It handles all the logic of the mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice The contract is very loosely based on the MakerDAO DSS (DAI) system, but with a few key differences.
 */
contract DSCEngine {
 //update
}

