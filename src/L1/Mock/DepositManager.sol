// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IDepositManager } from "../../interfaces/IDepositManager.sol";
import { ISeigManager } from "../../interfaces/ISeigManager.sol";


contract DepositManager is IDepositManager, ERC20 {
    using SafeERC20 for IERC20;

    address public wton;
    address public seigManager;

    event Deposited(address layer2, address account, uint256 amount);

    constructor(address _wton) ERC20("staked WTON","sWTON"){
        wton = _wton;
    }

    function setSeigManager(address _seigManager) external {
        seigManager = _seigManager;
    }

    function deposit(address layer2, uint256 amount) external returns (bool) {
        require(msg.sender != address(0) && amount != 0, "zero amount or zero address");

        ISeigManager(seigManager).addStake(msg.sender, amount);
       
        IERC20(wton).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Deposited(layer2, msg.sender, amount);

        return true;    
    }
}