// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { L1WrappedStakedTON } from "./L1WrappedStakedTON.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract L1WrappedStakedTONFactory is Ownable {

    address public l1wton;

    event WSTONTokenCreated(address token, address layer2Address);

    constructor(address _l1wton) Ownable(msg.sender) {
        l1wton = _l1wton;
    }
    
    function createWSTONToken(
        address _layer2Address,
        address _l1StandardBridge,
        address _l2wston,
        address _depositManager,
        address _seigManager,
        uint256 _totalAmountStaked,
        uint256 _lastRewardsDistributionDate
    ) external onlyOwner {
        require(_layer2Address != address(0), "Must provide a layer2 candidate");
        require(_l1StandardBridge != address(0), "Must provide a bridge address");

        L1WrappedStakedTON wston = new L1WrappedStakedTON(
            _layer2Address,
            _l1StandardBridge,
            _l2wston,
            l1wton,
            _depositManager,
            _seigManager,
            _totalAmountStaked,
            _lastRewardsDistributionDate
        );

        emit WSTONTokenCreated(address(wston),_layer2Address);
    }
}