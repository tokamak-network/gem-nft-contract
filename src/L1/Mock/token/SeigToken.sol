// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ISeigManager } from "../../../interfaces/ISeigManager.sol";

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { ERC20OnApprove } from "./ERC20OnApprove.sol";

contract SeigToken is Ownable, ERC20OnApprove {
  ISeigManager public seigManager;
  bool public callbackEnabled;

  constructor() Ownable(msg.sender) {}
  function enableCallback(bool _callbackEnabled) external onlyOwner {
    callbackEnabled = _callbackEnabled;
  }

  function setSeigManager(ISeigManager _seigManager) external onlyOwner {
    seigManager = _seigManager;
  }

}