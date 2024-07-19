// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GemFactory } from "./GemFactory.sol";

contract Treasury is GemFactory {
    using SafeERC20 for IERC20;


    // Function to check the balance of TON token within the contract
    function getTonBalance() external view returns (uint256) {
        return IERC20(ton).balanceOf(address(this));
    }

    // Function to check the balance of TitanWSTON token within the contract
    function getTitanwstonBalance() external view returns (uint256) {
        return IERC20(titanwston).balanceOf(address(this));
    }
    

}