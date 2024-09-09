// SPDX-License-Identifier: MIT
// Have our Invariants aka properties

// what are our invariants

// 1. The total supply of the DSC should be less than the total value of collateral

// 2. Getter view function should never revert <- evergreen Invariant

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {console} from "forge-std/console.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OpenInvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig helper;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, engine, helper) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = helper.activeNetworkConfig();
        console.log("Deployed DSC at address: ", address(engine));
        // targetContract(address(engine));
    }

    // function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
    //     console.log("in");
    //     // get the value of all the collateral in the protocol
    //     // compare it to all the debt (dsc)
    //     uint256 totalSupply = dsc.totalSupply();
    //     uint256 totalWethDeposited = ERC20Mock(weth).balanceOf(address(engine));
    //     uint256 totalWbtcDeposited = ERC20Mock(wbtc).balanceOf(address(engine));

    //     uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
    //     uint256 wbtcValue = engine.getUsdValue(wbtc, totalWbtcDeposited);

    //     assert(wethValue + wbtcValue > totalSupply);
    // }
}
