// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {WstonSwapPoolV2} from "../../../src/L2/WstonSwapPoolV2.sol";

contract MockWstonSwapPoolUpgraded is WstonSwapPoolV2 {

    uint256 internal counter;

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }  

}