// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./L2BaseTest.sol";
import "../../src/L2/Tokamak-uniswap/UniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstonSwapTest is L2BaseTest {

    IERC20 public ton;
    IERC20 public wston;
    address public uniswapV3Pool;

    uint256 fee = 3000;

    function setUp() public {

        super.setUp();
        // Deploy the pool contract
        uniswapV3Pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(address(ton), address(wston), fee))}());

    }  
}
