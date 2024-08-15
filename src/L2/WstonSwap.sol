// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;
pragma abicoder v2;

import '../interfaces/IV3SwapRouter.sol';
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WstonSwap {
    using SafeERC20 for IERC20;

    IV2SwapRouter public immutable swapRouter;
    address public immutable ton;
    address public immutable wston;
    uint24 public constant feeTier = 3000;

    constructor(IV2SwapRouter _swapRouter, address _ton, address _wston) {
        swapRouter = _swapRouter;
        wston = _wston;
        ton = _ton;
    }

    function swapTONForWSTON(uint256 amountIn) external returns (uint256 amountOut) {

        // Transfer the specified amount of ton to this contract.
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amountIn);
        // Approve the router to spend ton.
        IERC20(ton).safeApprove(address(swapRouter), amountIn);
        // Note: To use this example, you should explicitly set slippage limits, omitting for simplicity
        uint256 minOut = /* Calculate min output */ 0;
        uint160 priceLimit = /* Calculate price limit */ 0;
        // Create the params that will be used to execute the swap
        swapRouter.ExactInputSingleParams memory params =
            swapRouter.ExactInputSingleParams({
                tokenIn: ton,
                tokenOut: wston,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }
}