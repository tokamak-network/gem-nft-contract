// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IRefactor } from "../interfaces/IRefactor.sol";

contract WrappedStakedTONStorage {
    


    uint256 public constant REFACTOR_DIVIDER = 2;
    
    address public layer2;
    address public depositManager;
    address public seigManager;
    address public wton;

    uint256 public stakingIndex;

    uint256 public factor;

    bool paused;

    mapping (address => IRefactor.Balance) public balances;
    IRefactor.Balance[] public Balances;

    // Main events
    event Deposited(address account, uint256 amount);
    event WithdrawalRequested(address account, uint256 amount);


    // Pause Events
    event Paused(address account);
    event Unpaused(address account);
}