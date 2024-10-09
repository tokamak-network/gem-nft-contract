//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract AuthRole {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE");
}
