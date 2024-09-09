// SPDX-Lcense-Identifier: MIT
pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

// import 
// Handler is going to narrow down the way we call function

contract Handler is Test  {

    DSCEngine engine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // max unit 96 value

    constructor( DSCEngine _engine, DecentralizedStableCoin _dsc) {
        // constructor
        engine = _engine;
        dsc = _dsc;
        address [] memory tokens = engine.getCollateralTokens();
        weth = ERC20Mock(tokens[0]);
        wbtc = ERC20Mock(tokens[1]);

    }

    // redeem Collateral <-
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral ) public {
        amountCollateral = bound(amountCollateral,1, MAX_DEPOSIT_SIZE);
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        // console.log("collateral", address(collateral));
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
    }

    // Helper function
    function _getCollateralFromSeed(uint256 collateralSeed) public view returns (ERC20Mock) {
        // return engine.getCollateralFromSeed(seed);
        if(collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        } 
    }
}
// contract Handler is Test  {

//     DSCEngine engine;
//     DecentralizedStableCoin dsc;
//     address weth;
//     address wbtc;
//     constructor( DSCEngine _engine, DecentralizedStableCoin _dsc) {
//         // constructor
//         engine = _engine;
//         dsc = _dsc;
//         address [] memory tokens = engine.getCollateralTokens();
//         weth = tokens[0];
//         wbtc = tokens[1];

//     }

//     // redeem Collateral <-
//     function depositCollateral(uint256 collateralSeed, uint256 amountCollateral ) public {
//         address collateral = _getCollateralFromSeed(collateralSeed);
//         console.log("collateral", collateral);
//         engine.depositCollateral(address(collateral), amountCollateral);
//     }

//     // Helper function
//     function _getCollateralFromSeed(uint256 collateralSeed) public view returns (address) {
//         // return engine.getCollateralFromSeed(seed);
//         if(collateralSeed % 2 == 0) {
//             return weth;
//         } else {
//             return wbtc;
//         } 
//     }
// }