// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISeigManager } from "../../interfaces/ISeigManager.sol";


contract SeigManager is ISeigManager {

    address depositManager;

    mapping(address => uint256) public userStaked;
    address[] public stakers;

    constructor(address _depositManager) {
        depositManager = _depositManager;
    }

    function addStake(address user, uint256 amount) external {
        userStaked[user] += amount;
        stakers.push(user);
    }

    function stakeOf(address /*layer2*/, address account) external view returns (uint256) {
        return userStaked[account];
    }

    function updateSeigniorage() external returns(bool) {
        for (uint256 i = 0; i < stakers.length; i++) {
            userStaked[stakers[i]] ++;
        }
        return true;
    }
}