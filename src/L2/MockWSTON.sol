// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWSTON is ERC20 {
    constructor() ERC20("Titan WSTON", "TITANWSTON") {
        _mint(msg.sender, 1000000 * (10 ** 27));
    }
}
