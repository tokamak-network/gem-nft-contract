// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {WstonSwapPool} from "../../../src/L2/WstonSwapPool.sol";

contract MockWstonSwapPoolUpgraded is WstonSwapPool {

    uint256 internal counter;

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }  

}