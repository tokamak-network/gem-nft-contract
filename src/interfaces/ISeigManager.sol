// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


interface ISeigManager {

  function stakeOf(address layer2, address account) external view returns (uint256);
  function addStake(address user, uint256 amount) external;
  function updateSeigniorage() external returns(bool);

}
