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

pragma solidity ^0.8.19;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @title DecentralizedStableCoin
 * @author Mohd Farman 
 * Collateral: Exogenous (ETH & BTC)
 * Minting (Stability Mechanism): Decentralized (Algorithmic)asd
 * Value (Relative Stability): Anchored (Pegged to USD)
 *
 * This is the contract meant to be owned by DSCEngine. This contract is just the ERC20 implementation of our Stable Coin System.
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {

    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsbalance();
    error DecentralizedStableCoin__NotZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(address(0)){}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if(_amount <= 0){
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if(balance < _amount){
            revert DecentralizedStableCoin__BurnAmountExceedsbalance();
        }
        // Use the burn function on super or parent class, in our case use the burn function available in (ERC20Burnable)
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool)  {
        if(_to == address(0x0)){
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if(_amount <=0){
          revert DecentralizedStableCoin__MustBeMoreThanZero();   
        }

        //not using super here because we are not overridding any function, 
        _mint(_to, _amount);
        return true;
    }

}
