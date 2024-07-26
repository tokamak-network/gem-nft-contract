// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _setupDecimals(decimals_);
        _mint(msg.sender, 1000000 * 10**uint256(decimals_)); // Mint 1,000,000 tokens to the deployer
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    uint8 private _decimals;

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
