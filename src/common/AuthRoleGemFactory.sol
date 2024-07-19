//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract AuthRoleGemFactory {
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");
}
