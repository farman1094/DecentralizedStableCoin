// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {console} from "forge-std/console.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngineTest is Test {
    // ETH = 3000
    // WBTC = 60000
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig helper;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, helper) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = helper.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_USER_BALANCE);
    }
    ////////////////////////
    // Constructor Test ///
    ///////////////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressedAndPriceFeedAddressesMustBeSameLength.selector);
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    //////////////////////
    // Price Feed Test ///
    /////////////////////

    function testGetUsdValue() public view {
        console.log(block.chainid);
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);

        uint256 expectedUsdBtc = 900000e18;
        uint256 actualUsdBtc = engine.getUsdValue(wbtc, ethAmount);
        assertEq(actualUsd, expectedUsd);
        assertEq(actualUsdBtc, expectedUsdBtc);
    }

    function testGetTokenAmountFromUSD() public view {
        uint256 usdAmount = 100 ether;
        // 2000 / ETH, 100$ =
        uint256 expectedAmount = 0.05 ether;
        uint256 actualAmount = engine.getTokenAmountFromUSD(weth, usdAmount);
        assertEq(actualAmount, expectedAmount);
    }

    //////////////////////////
    //   Mint DSC Test     ///
    //////////////////////////
    function testMinting() public depositCollateral {
        vm.startPrank(USER);
        uint256 valueOfTokenInUSD = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 liq_threshold = 50;
        uint256 liq_precision = 100;
        uint256 rightValueWithThreshold = (valueOfTokenInUSD * liq_threshold) / liq_precision;
        uint256 expectedDscMinted = 10000e18;
        uint256 expectedUsdCollateral = 20000e18;
        engine.mintDsc(rightValueWithThreshold);
        (uint256 actualDSCminted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        assertEq(expectedDscMinted, actualDSCminted);
        assertEq(expectedUsdCollateral, collateralValueInUsd);
        vm.stopPrank();
    }

    /////////////////////////////
    // Depost Collateral Test ///
    /////////////////////////////
    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertWithUnapprovedToken() public {
        ERC20Mock ranToken = new ERC20Mock("Ran", "Ran", USER, 1000e18);
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        engine.depositCollateral(address(ranToken), 10e18);
        vm.stopPrank();
    }

    function testToRevertDSCEngine__DepositFailed() public {
        // Mock the `transferFrom` function to return false
        vm.mockCall(
            weth,
            abi.encodeWithSelector(IERC20.transferFrom.selector, USER, address(engine), AMOUNT_COLLATERAL),
            abi.encode(false) // This will cause the transfer to "fail"
        );

        vm.startPrank(USER);
        // Expect the revert with DSCEngine__DepositFailed error
        vm.expectRevert(DSCEngine.DSCEngine__DepositFailed.selector);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        uint256 expectedToken = engine.getTokenAmountFromUSD(weth, collateralValueInUsd);
        uint256 expectedUsdValueShouldBe = 20000e18;
        uint256 expectedDscMinted = 0;

        assertEq(totalDscMinted, expectedDscMinted);
        assertEq(expectedUsdValueShouldBe, collateralValueInUsd);
        assertEq(expectedToken, AMOUNT_COLLATERAL);
    }

    /////////////////////////////
    /// Mint And Deposit Test ///
    /////////////////////////////
    function testDepositCollateralAndMintDSC() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, AMOUNT_COLLATERAL);
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);

        uint256 balAfterDeposit = engine.getUsdValue(weth, 10e18);
        uint256 balAfterDepositDSC = 10e18;
        assertEq(collateralValueInUsd, balAfterDeposit);
        assertEq(totalDscMinted, balAfterDepositDSC);

        vm.stopPrank();
    }

    function testDepositCollateralAndMintDscRevertDSCEngine__BreaksHealthFactor() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        // vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector,5e17);
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 healthFactor = engine.calculateHealthFactor(20000e18, collateralValueInUsd);
        // console.log("Health Factor: ", healthFactor);

        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, healthFactor));
        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, 20000e18);
        vm.stopPrank();
    }

    /////////////////////////////
    // Redeem Collateral Test ///
    /////////////////////////////

    function testRevertsIfRedeemedCollateralIsZero() public depositCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRedeemCollateral() public depositCollateral {
        vm.startPrank(USER);
        // engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        // uint256 balAfterRedeem = 0;
        engine.redeemCollateral(weth, 9 ether);
        uint256 balAfterRedeem = engine.getUsdValue(weth, 1e18);
        (, uint256 collaterlValueInusd) = engine.getAccountInformation(USER);
        assertEq(collaterlValueInusd, balAfterRedeem);
        vm.stopPrank();
    }

    function testToRevertInRedeemDSCEngine__TransferFailed() public depositCollateral {
        // Mock the `transferFrom` function to return fale
        vm.mockCall(
            weth,
            abi.encodeWithSelector(ERC20Mock(weth).transfer.selector, USER, AMOUNT_COLLATERAL),
            abi.encode(false) // This will cause the transfer to "fail"
        );
        //bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        //bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);

        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    // testRedeemCollateralFail

    /////////////////////////////
    //   Health factor Test   ///
    /////////////////////////////
    function testToRevertBreaksHealthFactor() public depositCollateral {
        uint256 amounToMint = 25000e18;
        vm.startPrank(USER);
        uint256 collateralValueInUsd = engine.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 healthFactor = engine.calculateHealthFactor(amounToMint, collateralValueInUsd);

        // Issue because of output in custom error
        // vm.expectRevert(DSCEngine.DSCEngine__BreaksHealthFactor.selector);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, healthFactor));

        engine.mintDsc(amounToMint);
        console.log("DSC minted: ", amounToMint);
        vm.stopPrank();
    }
    ////////////////////////
    //   Burn DSC Test   ///
    ////////////////////////

    modifier depositCollateralAndMintDSC() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, AMOUNT_COLLATERAL);
        dsc.approve(address(engine), AMOUNT_COLLATERAL);
        vm.stopPrank();
        // engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        // ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        _;
    }

    function testToCheckIfBurnDscIsWorking() public depositCollateralAndMintDSC {
        vm.startPrank(USER);
        engine.burnDsc(AMOUNT_COLLATERAL);
        (uint256 AfterBurningAmount,) = engine.getAccountInformation(USER);
        uint256 expecBalAfterBurning = 0;
        assertEq(AfterBurningAmount, expecBalAfterBurning);
    }






    
}
