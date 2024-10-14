// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {GemFactory} from "../../../src/L2/GemFactory.sol";

contract MockGemFactoryUpgraded is GemFactory {

    function setRareMiningTry(uint8 _rareMiningTry) external {
        RareminingTry= _rareMiningTry;
    }

}