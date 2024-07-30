// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { WSTONManagerStorage } from "./WSTONManagerStorage.sol";

contract WSTONManager is WSTONManagerStorage {

    
    modifier onlyL2CrossDomainMessenger() {
        require(msg.sender == l2CrossDomainMessenger, "caller is not L2CrossDomainMessenger contract");
        _;
    }

    constructor(address _l2CrossDomainManager) {
        l2CrossDomainMessenger = _l2CrossDomainManager;
    }
    
    function onWSTONDeposit(
        address _recipient,
        uint256 _amount,
        uint256 _stakingIndex,
        uint256 _depositTime
    ) external onlyL2CrossDomainMessenger {
        StakingTracker memory _stakingTracker = StakingTracker({
            holderId: 0,
            amount: _amount,
            stakingIndex: _stakingIndex,
            depositTime: _depositTime
        });
        stakingTrackers.push(_stakingTracker);
        wstonOwner[_recipient] = _stakingTracker;
    }
}