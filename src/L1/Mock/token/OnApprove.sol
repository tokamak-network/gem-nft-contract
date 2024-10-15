
// SPDX-License-Identifier: MIT
pragma solidity 0.8.25; 

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract OnApprove is ERC165 {
  constructor() {
    // _registerInterface(OnApprove(this).onApprove.selector);
  }

  function onApprove(address owner, address spender, uint256 amount, bytes calldata data) external virtual returns (bool) {}
}