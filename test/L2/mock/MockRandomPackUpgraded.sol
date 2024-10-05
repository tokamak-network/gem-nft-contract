// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {RandomPack} from "../../../src/L2/RandomPack.sol";

contract MockRandomPackUpgraded is RandomPack {

    uint256 internal counter;

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }  

}