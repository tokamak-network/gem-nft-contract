// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IRefactor } from "../interfaces/IRefactor.sol";

contract WrappedStakedTONStorage {

    struct DepositTracker {
        uint256 stakingIndex;
        uint256 depositTime;
    }

    DepositTracker[] public depositTrackers;

    uint32 public constant MIN_DEPOSIT_GAS_LIMIT = 210000;
    
    address public layer2;
    address public depositManager;
    address public seigManager;
    address public wton;
    address public titanwston;
    address public l1StandardBridge;

    bool paused;

    // Main events
    event Deposited(address account, uint256 amount);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);
}