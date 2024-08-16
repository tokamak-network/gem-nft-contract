// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../src/L2/Swap/WstonSwap.sol";
import "../../src/L2/Swap/IV3SwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstonSwapTest is Test {
    WstonSwap public wstonSwap;
    IV3SwapRouter public swapRouter;
    IERC20 public ton;
    IERC20 public wston;

    address public tonAddress = address(0x1);
    address public wstonAddress = address(0x2);
    address public swapRouterAddress = address(0x3);
    address public user = address(0x4);

    function setUp() public {
        // Deploy mock contracts
        swapRouter = IV3SwapRouter(swapRouterAddress);
        ton = IERC20(tonAddress);
        wston = IERC20(wstonAddress);

        // Deploy the WstonSwap contract
        wstonSwap = new WstonSwap(swapRouter, tonAddress, wstonAddress);

        // Label addresses for easier debugging
        vm.label(tonAddress, "TON");
        vm.label(wstonAddress, "WSTON");
        vm.label(swapRouterAddress, "SwapRouter");
        vm.label(user, "User");
    }

    function testSwapExactInputSingle() public {
        uint256 amountIn = 1000;
        uint256 amountOut = 2000;

        // Mock the behavior of the swapRouter
        vm.mockCall(
            swapRouterAddress,
            abi.encodeWithSelector(IV3SwapRouter.exactInputSingle.selector),
            abi.encode(amountOut)
        );

        // Transfer TON to the user
        deal(tonAddress, user, amountIn);

        // Approve the WstonSwap contract to spend TON
        vm.prank(user);
        ton.approve(address(wstonSwap), amountIn);

        // Perform the swap
        vm.prank(user);
        uint256 result = wstonSwap.swapExactInputSingle(amountIn);

        // Assert the expected output
        assertEq(result, amountOut);
    }

    function testSwapExactOutputSingle() public {
        uint256 amountOut = 2000;
        uint256 amountInMaximum = 3000;
        uint256 amountIn = 2500;

        // Mock the behavior of the swapRouter
        vm.mockCall(
            swapRouterAddress,
            abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector),
            abi.encode(amountIn)
        );

        // Transfer TON to the user
        deal(tonAddress, user, amountInMaximum);

        // Approve the WstonSwap contract to spend TON
        vm.prank(user);
        ton.approve(address(wstonSwap), amountInMaximum);

        // Perform the swap
        vm.prank(user);
        uint256 result = wstonSwap.swapExactOutputSingle(amountOut, amountInMaximum);

        // Assert the expected input
        assertEq(result, amountIn);

        // Assert the remaining TON balance
        uint256 remainingBalance = ton.balanceOf(user);
        assertEq(remainingBalance, amountInMaximum - amountIn);
    }
}
