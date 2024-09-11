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

contract Handler is Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // max unit 96 value

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        // constructor
        engine = _engine;
        dsc = _dsc;
        address[] memory tokens = engine.getCollateralTokens();
        weth = ERC20Mock(tokens[0]);
        wbtc = ERC20Mock(tokens[1]);
    }


    // mint dsc
    function mintDsc(uint256 amount) public {
        vm.startPrank(msg.sender);
         (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(msg.sender);
        // if(amount > collateralValueInUsd) return;
        //doubt
        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) - int256(totalDscMinted);
        console.log("amount", amount);
        console.log("collateralValueInUsd",collateralValueInUsd);
        console.log("totalDscMinted",totalDscMinted);
        if(maxDscToMint < 0) {
            return;
        }
        amount = bound(amount, 0, uint256(maxDscToMint));
        console.log("boundAmount", amount);
        if(amount == 0){
            return;
        }
        // startPrank was here before causing the errors 
        engine.mintDsc(amount);
        vm.stopPrank();

    }

    // redeem Collateral <-
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
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
        if (collateralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToReddem = engine.getCollateralBalanceOfUser(address(collateral), msg.sender);
        // console.log("maxCollateralToReddem", maxCollateralToReddem);
        // console.log("amountCollateral", amountCollateral);
        if (maxCollateralToReddem == 0) {
            return;
        }
        // error in this if min is 1 and max is 0 (therefore comparing with maxCollateralToReddem)
        amountCollateral = bound(amountCollateral, 1, maxCollateralToReddem);
        engine.redeemCollateral(address(collateral), amountCollateral);
    }

    
    /**@notice another way of doing this Need to confirm it later */
    //     function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
    //     ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
    //     uint256 maxCollateralToReddem = engine.getCollateralBalanceOfUser(address(collateral), msg.sender);
    //     console.log("maxCollateralToReddem", maxCollateralToReddem);
    //     console.log("amountCollateral", amountCollateral);
    //     amountCollateral = bound(amountCollateral, 0, maxCollateralToReddem);
    //     if (amountCollateral == 0) {
    //         return;
    //     }
    //     engine.redeemCollateral(address(collateral), amountCollateral);
    // }    



}
