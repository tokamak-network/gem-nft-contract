// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISeigManager } from "../../../interfaces/ISeigManager.sol";
import { SeigToken } from "./SeigToken.sol";


/**
 * @dev Current implementations is just for testing seigniorage manager.
 */
contract TON is ERC20, Ownable, SeigToken {
  constructor() ERC20("Tokamak Network Token", "TON") {}

      function mint(address _to, uint256 _amount) public virtual {
        _mint(_to, _amount);
    }

}