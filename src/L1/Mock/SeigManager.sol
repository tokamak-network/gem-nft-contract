// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISeigManager } from "../../interfaces/ISeigManager.sol";


contract SeigManager is ISeigManager {

    address depositManager;

    mapping(address => uint256) public userStaked;

    constructor(address _depositManager) {
        depositManager = _depositManager;
    }

    function addStake(address user, uint256 amount) external {
        userStaked[user] += amount;
    }

    function stakeOf(address /*layer2*/, address account) external view returns (uint256) {
        return userStaked[account];
    }
}