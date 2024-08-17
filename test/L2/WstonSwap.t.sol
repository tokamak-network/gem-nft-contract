// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "./L2BaseTest.sol";
import "../../src/L2/Tokamak-uniswap/UniswapV3Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstonSwapTest is L2BaseTest {

    address public uniswapV3Factory;
    address public WstonPool;
    uint256 fee = 3000;

    function setUp() public override {

        super.setUp();

        vm.startPrank(owner);
        // Deploy the pool contract
        uniswapV3Factory = address(new UniswapV3Factory());
        WstonPool = UniswapV3Factory(uniswapV3Factory).createPool(ton, wston, 3000);
        

        vm.stopPrank();

    }  
}
