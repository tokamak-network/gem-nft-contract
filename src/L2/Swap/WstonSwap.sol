// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;
pragma abicoder v2;

import { IV3SwapRouter } from './IV3SwapRouter.sol';
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WstonSwap {
    using SafeERC20 for IERC20;

    IV3SwapRouter public immutable swapRouter;
    address public immutable ton;
    address public immutable wston;
    uint24 public constant feeTier = 3000;

    constructor(IV3SwapRouter _swapRouter, address _ton, address _wston) {
        swapRouter = _swapRouter;
        wston = _wston;
        ton = _ton;
    }

     /// @notice swapExactInputSingle swaps a fixed amount of TON for a maximum possible amount of WSTON
    /// using the TON/WSTON 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its TON for this function to succeed.
    /// @param amountIn The exact amount of TON that will be swapped for WSTON.
    /// @return amountOut The amount of WSTON received.
    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        // Transfer the specified amount of ton to this contract.
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amountIn);
        // Approve the router to spend ton.
        IERC20(ton).approve(address(swapRouter), amountIn);
        // Note: To use this example, you should explicitly set slippage limits, omitting for simplicity
        uint256 minOut = /* Calculate min output */ 0;
        uint160 priceLimit = /* Calculate price limit */ 0;
        // Create the params that will be used to execute the swap
        IV3SwapRouter.ExactInputSingleParams memory params =
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: ton,
                tokenOut: wston,
                fee: feeTier,
                recipient: msg.sender,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of TON for a fixed amount of WSTON.
    /// @dev The calling address must approve this contract to spend its TON for this function to succeed. As the amount of input TON is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WSTON to receive from the swap.
    /// @param amountInMaximum The amount of TON we are willing to spend to receive the specified amount of WSTON.
    /// @return amountIn The amount of TON actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // Transfer the specified amount of TON to this contract.
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amountInMaximum);

        // Approve the router to spend the specifed `amountInMaximum` of TON.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        IERC20(ton).approve(address(swapRouter), amountInMaximum);

        IV3SwapRouter.ExactOutputSingleParams memory params =
            IV3SwapRouter.ExactOutputSingleParams({
                tokenIn: ton,
                tokenOut: wston,
                fee: feeTier,
                recipient: msg.sender,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            IERC20(ton).approve(address(swapRouter), 0);
            IERC20(ton).safeTransfer(msg.sender, amountInMaximum - amountIn);
        }
    }
}
