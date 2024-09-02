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
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    
    /////////////
    // Errors ///
    /////////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressedAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__TokenNotSupported();
    error DSCEngine__DepositFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
 
    ///////////////////////
    /// State Variables ///
    ///////////////////////
    uint256 private constant ADDITIONAL_PRICE_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overCOLLATERIZED REQUIRED
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant PRECISION = 1e18; // Needed to check (with patrick)
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // Needed to check (with patrick)

    mapping(address token => address priceFeed) public s_priceFeeds; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) public s_CollateralDeposited; //userToTokenToCollateral
    mapping(address user => uint256 amountDscMinted) public s_DSCMinted; //userToDSCMinted

    address[] private s_collateralToken;
    
    //Immutables
    DecentralizedStableCoin private immutable i_dsc;

     
    /////////////////
    ////   Events  //
    /////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event DscAmountMinted(address indexed user, uint256 indexed amount);

     
    ////////////////
    // Modifiers  //
    ////////////////
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

    //////////////////
    // Construtor  ///
    /////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressedAndPriceFeedAddressesMustBeSameLength();
        }

        // For example ETH / USD, BTC / USD, MKR / USD
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralToken.push(tokenAddresses[i]);
        }

        // Initialize the DSC
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    
    ////////////////////////
    // External function ///
    ////////////////////////
    function depositCollateralAndMintDSC() external {}

    /**
     * @notice follow CEI (Check-Effects-Interactions) pattern
     * @param tokenCollateralAddress The address of the token to be deposited as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_CollateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__DepositFailed();
        }
    }

    function redeemCollateralForDSC() external {}
    function redeemCollateral() external {}

    /**
     * @notice follow CEI (Check-Effects-Interactions) pattern
     * @param amountDscToMint The amount of DSC to mint
     * @notice they must have more collateral value then minimum
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much revert
        _revertIfHealthFactorIsBroken(msg.sender);
        emit DscAmountMinted(msg.sender, amountDscToMint);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}


    ///////////////////////////////////
    // Internal and Private function //
    ///////////////////////////////////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[msg.sender];
        collateralValueInUsd = getCollateralValueInUSD(user);
        return (totalDscMinted, collateralValueInUsd);
    }

    /**
     * @notice returns how close to liquidation a user is
     * If a user goes below 1, then they can liquidated
     */
    function _healthFactor(address user) internal view returns (uint256) {
        // total dsc minted
        // total collateral value

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // 1000 ETH * 50  = 50,000 / 100 = 500
        // 150 * 50 = 7500 / 100 = (75 / 100) < 1

        // $1000 ETH / 100 DSC
        // 1000 ETH * 50  = 50,000 / 100 = (500 / 100) > 1
        // 500 * 1e18 / 100
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // return (collateralValueInUsd / totalDscMinted)
    }

    // check Health Factor(do they have enough collateral)
    // Revert if Health Factor is broken
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    // Public view function
    function getCollateralValueInUSD(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each token, get the amount they have deposited. Map it to
        // the price feed and get the value in USD
        for (uint256 i = 0; i < s_collateralToken.length; i++) {
            address token = s_collateralToken[i];
            uint256 amount = s_CollateralDeposited[user][token];
            totalCollateralValueInUsd = getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        // ( ,int256 price,,,) = priceFeed.latestRoundData()
        (, int256 price,,,) = priceFeed.latestRoundData();

        // 1 ETH = $1000
        // Price return from the CL = 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_PRICE_PRECISION) * amount) / 1e18; // (1000 * 1e8 * (1e10)) * PRECISION1000 * 1e18
    }
}
