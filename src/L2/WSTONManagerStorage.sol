// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract WSTONManagerStorage {

    mapping(address => mapping(uint256 => uint256)) public userBalanceByIndex;

}