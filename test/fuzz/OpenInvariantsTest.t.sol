// // SPDX-License-Identifier: MIT
// // Have our Invariants aka properties

// // what are our invariants

// // 1. The total supply of the DSC should be less than the total value of collateral

// // 2. Getter view function should never revert <- evergreen Invariant

pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "script/DeployDSC.s.sol";
// import {DSCEngine} from "src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {console} from "forge-std/console.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

// contract OpenInvariantsTest is StdInvariant, Test {
//     DeployDSC deployer;
//     DSCEngine engine;
//     DecentralizedStableCoin dsc;
//     HelperConfig helper;

//     address ethUsdPriceFeed;
//     address btcUsdPriceFeed;
//     address weth;
//     address wbtc;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, engine, helper) = deployer.run();
//         (btcUsdPriceFeed , ethUsdPriceFeed , weth, wbtc,) = helper.activeNetworkConfig();
//          targetContract(address(engine));
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
//         uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));
//         uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
//         uint256 wbtcValue = engine.getUsdValue(wbtc, totalWbtcDeposited);

//         console.log("totalSupply",totalSupply);
//         console.log("wethValue",wethValue);
//         console.log("wbtcValue",wbtcValue);

//         assert(wethValue + wbtcValue >= totalSupply);
//     }
// }
