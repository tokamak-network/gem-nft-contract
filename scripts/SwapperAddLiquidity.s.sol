// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol"; // Import the console library
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWstonSwapPool {
    function addLiquidity(uint256 tonAmount, uint256 wstonAmount) external;
}

contract AddLiquidityScript is Script {
    function run() external {
        // Fetch addresses from environment variables
        address tonAddress = vm.envAddress("TON_ADDRESS");
        address wstonAddress = vm.envAddress("TITAN_WRAPPED_STAKED_TON");
        address poolAddress = vm.envAddress("WSTON_SWAP_POOL");

        uint256 tonAmount = 500 * 10**18; 
        uint256 wstonAmount = 500 * 10**27; // Adjusted for 27 decimals

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address deployerAddress = vm.addr(deployerPrivateKey);

        IERC20 ton = IERC20(tonAddress);
        IERC20 wston = IERC20(wstonAddress);
        IWstonSwapPool pool = IWstonSwapPool(poolAddress);

        // Approve the pool to spend TON and WSTON tokens
        ton.approve(poolAddress, tonAmount);
        wston.approve(poolAddress, wstonAmount);

        // Debugging: Check allowances
        //500000000000000000000
        uint256 tonAllowance = ton.allowance(deployerAddress, poolAddress);
        //500000000000000000000000000000
        uint256 wstonAllowance = wston.allowance(deployerAddress, poolAddress);
        console.log("TON Allowance: ", tonAllowance);
        console.log("WSTON Allowance: ", wstonAllowance);

        // Debugging: Check balances
        //5000.000000000000000000
        uint256 tonBalance = ton.balanceOf(deployerAddress);
        //4999.999999000000000000000000000
        uint256 wstonBalance = wston.balanceOf(deployerAddress);
        console.log("TON Balance: ", tonBalance);
        console.log("WSTON Balance: ", wstonBalance);

        // Debugging: Check addresses
        console.log("TON Address: ", tonAddress);
        console.log("WSTON Address: ", wstonAddress);
        console.log("Pool Address: ", poolAddress);
        console.log("Deployer Address: ", deployerAddress);

        // Debugging: Check before adding liquidity
        console.log("Before addLiquidity call");

        // Add liquidity to the pool
        pool.addLiquidity(tonAmount, wstonAmount);


        // Debugging: Check after adding liquidity
        console.log("After addLiquidity call");

        vm.stopBroadcast();
    }
}
