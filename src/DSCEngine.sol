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
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    error DSCEngine__DepositFailed();

    // State Variables
    mapping(address token => address priceFeed) public s_priceFeeds; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) public s_CollateralDeposited; //userToTokenToCollateral
    mapping (address user => uint256 amountDscMinted) public s_DSCMinted; //userToDSCMinted

    //Immutables
    DecentralizedStableCoin private immutable i_dsc;


    //Events 
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event DscAmountMinted(address indexed user, uint256 indexed amount);
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
        if(!success) {
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
    }
    function burnDsc() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}


    // Internal & Private view Functions

    function _healthFactor() internal view returns (uint256) {
        // Calculate Health Factor
    } 
    function _revertIfHealthFactorIsBroken (address user) internal view {
        // check Health Factor
        // Revert if Health Factor is broken 
    }
}
