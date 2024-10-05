// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {GemFactory} from "../../../src/L2/GemFactory.sol";

contract MockGemFactoryUpgraded is GemFactory {

    uint256 internal counter;

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }  

}