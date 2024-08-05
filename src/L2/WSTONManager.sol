// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { WSTONManagerStorage } from "./WSTONManagerStorage.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract WSTONManager is WSTONManagerStorage, Ownable {

    constructor() Ownable(msg.sender) {}
    

}