// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract TreasuryStorage {

    struct StakingTracker{
        address initialHolder;
        address currentHolder;
        uint256 amount;
        uint256 stakingIndex;
        uint256 depositTime;
    }

    StakingTracker[] public stakingTrackers;

    address public l2CrossDomainMessenger;


    address internal _gemFactory;
    address internal _marketplace;

}