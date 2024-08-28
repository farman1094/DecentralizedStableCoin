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

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
// import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DSCEngine
 * @author Mohd Farman
 * This system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1$ peg.
 * The stablecoin has the properties:
 * - Exogenous Collateral: ETH & BTC
 * - Dollar pegged
 * - Algorithmic Stable
 *
 * It is similar to DAI if DAI had no governance, no fees and only backed by WETH and WBTC.
 *
 * Our DSC should always be "overcollatorized". At no point, should the value of the collateral be less than or equal to (<=) the $ backed value of the DSC.
 *
 * @notice The contract is the core of the DSC System. It handles all the logic of the mining and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice The contract is very loosely based on the MakerDAO DSS (DAI) system, but with a few key differences.
 */
contract DSCEngine is ReentrancyGuard {
    // Errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressedAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotSupported();

    // State Variables
    mapping(address token => address priceFeed) public s_priceFeeds; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) public s_CollateralDeposited; //userToTokenToCollateral

    //Immutables
    DecentralizedStableCoin private immutable i_dsc;

    // Modifier
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotSupported();
        }
        _;
    }

    // Constructor
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressedAndPriceFeedAddressesMustBeSameLength();
        }

        // For example ETH / USD, BTC / USD, MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        // Initialize the DSC
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // External Functions
    function depositCollateralAndMintDSC() external {}

    /**
     * @param tokenCollateralAddress The address of the token to be deposited as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {}
    function redeemCollateralForDSC() external {}
    function redeemCollateral() external {}
    function mintDsc() external {}
    function burnDsc() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}
}
