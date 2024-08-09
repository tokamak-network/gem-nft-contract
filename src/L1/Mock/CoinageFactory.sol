// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import { AutoRefactorCoinageProxy } from "../tokens/AutoRefactorCoinageProxy.sol";
import { CoinageFactoryI } from "./interfaces/CoinageFactoryI.sol";
import { RefactorCoinageSnapshot } from "./proxy/RefactorCoinageSnapshot.sol";

interface IIAutoRefactorCoinage {
  function initialize (
      string memory name_,
      string memory symbol_,
      uint256 factor_,
      address seigManager_
    ) external;
}

contract CoinageFactory is CoinageFactoryI, Ownable {
  // uint256 constant public RAY = 10 ** 27; // 1 RAY
  // uint256 constant internal _DEFAULT_FACTOR = RAY;
  uint256 constant internal _DEFAULT_FACTOR = 10 ** 27;

  address public autoCoinageLogic;

  constructor() Ownable(msg.sender) {}

  function setAutoCoinageLogic(address newLogic) external onlyOwner {
    autoCoinageLogic = newLogic;
  }

  function deploy() external override returns (address) {
    RefactorCoinageSnapshot c = new RefactorCoinageSnapshot();


    c.initialize(
      "StakedWTON",
      "sWTON",
      _DEFAULT_FACTOR,
      msg.sender
    );

    return address(c);
  }
}
