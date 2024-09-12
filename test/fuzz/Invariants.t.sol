// SPDX-License-Identifier: MIT
// Have our Invariants aka properties

// what are our invariants

// 1. The total supply of the DSC should be less than the total value of collateral

// 2. Getter view function should never revert <- evergreen Invariant

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig helper;
    Handler handler;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, helper) = deployer.run();
        (btcUsdPriceFeed, ethUsdPriceFeed, weth, wbtc,) = helper.activeNetworkConfig();
        // targetContract(address(engine));
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
        // don't call redeem collateral unless there is collateral to redeem
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));
        uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = engine.getUsdValue(wbtc, totalWbtcDeposited);
        console.log("totalSupply", totalSupply);
        console.log("wethValue", wethValue);
        console.log("wbtcValue", wbtcValue);
        console.log("totalWethDeposited", totalWethDeposited);
        console.log("totalWbtcDeposited", totalWbtcDeposited);
        console.log("deposittimesCalled", handler.deposittimesCalled());
        console.log("halfMinttimesCalled", handler.halfMinttimesCalled());
        console.log("MinttimesCalled", handler.MinttimesCalled());
        console.log("halfredeemtimesCalled", handler.halfredeemtimesCalled());
        console.log("redeemtimesCalled", handler.redeemtimesCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant__GetterViewFunctionShouldNeverRevert() public view {
        engine.getTokenAmountFromUSD(weth, 1);
        engine.getTokenAmountFromUSD(wbtc, 1);
        engine.getAccountCollateralValue(address(this));
        engine.getAccountInformation(address(this));
        engine.calculateHealthFactor(5, 10);
        engine.getUsdValue(weth, 1);
        engine.getUsdValue(wbtc, 1);
        engine.getCollateralTokenPriceFeed(weth);
        engine.getCollateralBalanceOfUser(address(this), weth);
        engine.getHealthFactor(address(this));
        engine.getDsc();
        engine.getCollateralTokens();
        engine.getMinHealthFactor();
        engine.getPrecision();
        engine.getPricePrecision();
        engine.getLiquidationThreshold();
        engine.getLiquidationBonus();
        engine.getAdditionalPricePrecision();
        engine.getLiquidationPrecision();
    }
}
