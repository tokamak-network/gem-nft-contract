// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


interface IDepositManager {

  function deposit(address layer2, uint256 amount) external returns (bool);
  function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
  function processRequest(address layer2, bool receiveTON) external returns (bool);
  function getDelayBlocks(address layer2) external view returns (uint256);
  function numPendingRequests(address layer2, address account) external view returns (uint256);
  function processRequests(address layer2, uint256 n, bool receiveTON) external returns (bool);
}
