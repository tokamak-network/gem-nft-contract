// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WSTONVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public isClaiming;
    address wston;

    event ClaimWSTONRewardsOnlL2();
    event Deposited(address to, uint256 amount);
    event ApprovedForOwner(address spender, uint256 amount);

    constructor(address _wston) Ownable(msg.sender) {
        isClaiming = false;
        wston = _wston;
    }

    function onDeposit(address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_to != address(0), "address zero");
        require(IERC20(wston).balanceOf(address(this)) >= _amount);

        IERC20(wston).safeTransferFrom(address(this), _to, _amount);

        emit Deposited(_to, _amount);
    }
    

    function claimWSTONRewards() external nonReentrant {
        isClaiming = true;
        emit ClaimWSTONRewardsOnlL2();
    }

    function distributeRewardsOnL2() external onlyOwner {
        isClaiming = false;
    }

    function approveForOwner(uint256 _amount) external onlyOwner {
        IERC20(wston).approve(msg.sender, _amount);
        emit ApprovedForOwner(msg.sender, _amount);
    }

}