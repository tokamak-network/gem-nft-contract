// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


interface IDepositManager {

  function deposit(address layer2, uint256 amount) external returns (bool);

}
