// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWTON is ERC20 {

    constructor(string memory _name, string memory _symbol, uint8 decimals_) ERC20(_name, _symbol) {
        _mint(msg.sender, 1000000 * 10**uint256(decimals_)); // Mint 1,000,000 tokens to the deployer
    }

    function decimals() public view virtual override returns (uint8) {
        return 27;
    }


}