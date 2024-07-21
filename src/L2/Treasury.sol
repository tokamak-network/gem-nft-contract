// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GemFactory } from "./GemFactory.sol";

contract Treasury is GemFactory {
    using SafeERC20 for IERC20;

    address internal _gemFactory;

    event Paused(address account);
    event Unpaused(address account);

    modifier onlyGemFactory() {
        require(msg.sender == _gemFactory, "not GemFactory");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyPauser whenNotPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    function transferWSTON(address _to, uint256 _amount) external whenNotPaused onlyGemFactory returns(bool) {
        require(_to != address(0), "address zero");
        uint256 contractWSTONBalance = getWSTONBalance();
        require(contractWSTONBalance >= _amount, "Unsuffiscient WSTON balance");

        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    // Function to check the balance of TON token within the contract
    function getTONBalance() public view returns (uint256) {
        return IERC20(ton).balanceOf(address(this));
    }

    // Function to check the balance of WSTON token within the contract
    function getWSTONBalance() public view returns (uint256) {
        return IERC20(wston).balanceOf(address(this));
    }
    
}