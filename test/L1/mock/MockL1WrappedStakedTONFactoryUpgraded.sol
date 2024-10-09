// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {L1WrappedStakedTONFactory} from "../../../src/L1/L1WrappedStakedTONFactory.sol";

contract MockL1WrappedStakedTONFactoryUpgraded is L1WrappedStakedTONFactory {

    uint256 internal counter;

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }  

}