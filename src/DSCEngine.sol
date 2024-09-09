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
import {console} from "forge-std/console.sol";
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
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();
    ///////////////////////
    /// State Variables ///
    ///////////////////////

    uint256 private constant ADDITIONAL_PRICE_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; //200% overCOLLATERIZED REQUIRED
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; //10% bonus
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant PRICE_PRECISION = 1e8;

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
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

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

    /**
     * @param tokenCollateralAddress The address of token to deposit as collateral
     * @param amountCollateral The amount of collateral to be deposited
     * @param amountDscToMint The amount of DSC to be Mint
     * @notice they funciton will deposit the collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    /**
     * @param tokenCollateralAddress The address of the token to be redeemed as collateral
     * @param amountCollateral The amount of collateral to redeem
     * @param amountDscToBurn The DSC token to burn
     * @notice this function burn DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDSC(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        //redeemCollateral already checking health factor
    }

    // if we do start nearing undercollaterized, we need someone to liquidate positions
    // $100 ETH backing $50 DSC
    // $20 ETH backing $50 DSC (now DSC not worth $1

    //$75 ETH backing $50 DSC
    // Liquidator take $75 ETH backing if burns off the $50 DSC

    // If someone is under collaterized we will pay you to collaterized the.

    /**
     * @notice this function will liquidate the user's collateral if they are undercollaterized
     * @param collateral The ERC20 collateral address to liquidated from the user
     * @param user The user who broken the health factor. Their _healthFactor should below MIN_HEALTH_FACTOR
     * @param debtToCover The amount of DSC you want to burn to improve user Health's Factor
     * @notice You can partially liquidate a user
     * @notice You will get a liquidation bonus for taking the users fund
     * @notice This function working assumes the protocol will be roughly 200% overcollaterized In order for this to work
     * @notice A known bug would be if the protocol is 100% or less collaterized, then we would not be able to incentivized the liquidator
     *  for e.g -> If the price of the collateral plummeted before anyone could be liquidated. Then
     */
    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // check the health factor of the user
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }

        // we want to burn DSC
        // Take their collateral
        // Bad user: $140 USD, $100 DSC
        // $100 of DSC === ??? ETH?
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUSD(collateral, debtToCover);

        // and give them a 10% bonus
        // so we are giving the liquidator a $110 of WETH for 100 DSC
        // we should implement a feature to liquidate in the event the protocol is insolvent
        // and sweep extra amounts into a treasury
        // 0.05 * 0.10 = 0.005 Getting total 0.055
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(user, msg.sender, collateral, totalCollateralToRedeem);
        // burn dsc
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    ////////////////////////
    // Public function   ///
    ////////////////////////

    /**
     * @notice follow CEI (Check-Effects-Interactions) pattern
     * @param tokenCollateralAddress The address of the token to be deposited as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
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

    // In order to redeem collateral:
    // 1 health factor must be over 1 after collateral pulled
    // DRY: don't repeat yourself

    //CEI
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /**
     * @notice follow CEI (Check-Effects-Interactions) pattern
     * @param amountDscToMint The amount of DSC to mint
     * @notice they must have more collateral value then minimum
     */
    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much revert
        _revertIfHealthFactorIsBroken(msg.sender);
        emit DscAmountMinted(msg.sender, amountDscToMint);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); //don't think it would exist
    }
    // function getHealthFactor() external view {}

    ///////////////////////////////////
    // Internal and Private function //
    ///////////////////////////////////
    /**
     * @dev Low level internal function, do not call unless the function calling it is checking for health factor being broken
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        private
    {
        //100-1000 (revert)
        s_CollateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////

    /**
     * @notice returns how close to liquidation a user is
     * If a user goes below 1, then they can liquidated
     */
    function _healthFactor(address user) internal view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    // check Health Factor(do they have enough collateral)
    // Revert if Health Factor is broken
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        // console.log("userHealthFactor",userHealthFactor);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function _getUsdValue(address token, uint256 amount) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        // ( ,int256 price,,,) = priceFeed.latestRoundData()
        (, int256 price,,,) = priceFeed.latestRoundData();

        // 1 ETH = $1000
        // Price return from the CL = 1000 * 1e8
        return (uint256(price) * amount) / PRICE_PRECISION; // (1000 * 1e8 * (1e10)) * PRECISION1000 * 1e18
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[msg.sender];
        collateralValueInUsd = getAccountCollateralValue(user);
        return (totalDscMinted, collateralValueInUsd);
    }

    function _calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)
        internal
        pure
        returns (uint256)
    {
        if (totalDscMinted == 0) {
            return type(uint256).max;
        }
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // PUblic & External View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function getTokenAmountFromUSD(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // $/ETH ETH?
        // $2000 / ETH. $1000 = 0.5 ETH
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_PRICE_PRECISION);
        // ($1000 * 1e18) / ($3000e8 * 1e10)
        //5 * 1e17
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each token, get the amount they have deposited. Map it to
        // the price feed and get the value in USD
        for (uint256 index = 0; index < s_collateralToken.length; index++) {
            address token = s_collateralToken[index];
            uint256 amount = s_CollateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getAccountInformation(address user)
        external
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        return _getAccountInformation(user);
    }

    function calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)
        external
        pure
        returns (uint256)
    {
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    function getUsdValue(
        address token,
        uint256 amount // in WEI
    ) external view returns (uint256) {
        return _getUsdValue(token, amount);
    }

    function getCollateralTokenPriceFeed(address token) external view returns (address) {
        return s_priceFeeds[token];
    }

    function getCollateralBalanceOfUser(address user, address collateralAddress) external view returns (uint256) {
        return s_CollateralDeposited[user][collateralAddress];
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(user);
    }

    function getDsc() external view returns (address) {
        return address(i_dsc);
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralToken;
    }

    function getMinHealthFactor() external pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getPricePrecision() external pure returns (uint256) {
        return PRICE_PRECISION;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() external pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getAdditionalPricePrecision() external pure returns (uint256) {
        return ADDITIONAL_PRICE_PRECISION;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }
}
