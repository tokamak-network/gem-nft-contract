// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract WSTONManagerStorage {

    struct StakingTracker{
        uint256 amount;
        uint256 stakingIndex;
        uint256 depositTime;
    }

    StakingTracker[] public stakingTrackers;

    address public l2CrossDomainMessenger;

}