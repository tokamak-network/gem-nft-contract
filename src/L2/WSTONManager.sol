// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { WSTONManagerStorage } from "./WSTONManagerStorage.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract WSTONManager is WSTONManagerStorage, Ownable {

    constructor() Ownable(msg.sender) {}
    
    function onWSTONDeposit(
        address _account,
        uint256 _amount,
        uint256 _stakingIndex,
        uint256 _depositTime
    ) external onlyOwner {
        StakingTracker memory _stakingTracker = StakingTracker({
            currentHolder: _account,
            amount: _amount,
            stakingIndex: _stakingIndex,
            depositTime: _depositTime
        });
        stakingTrackers.push(_stakingTracker);
        wstonOwner[_account] = _stakingTracker;
    }
}