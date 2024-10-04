// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


interface ISeigManager {

  function stakeOf(address layer2, address account) external view returns (uint256);
  function stakeOf(address account) external view returns (uint256);
  function addStake(address user, uint256 amount) external;
  function updateSeigniorageLayer(address layer2) external returns(bool);
  function lastSeigBlock() external view returns (uint256);

}
