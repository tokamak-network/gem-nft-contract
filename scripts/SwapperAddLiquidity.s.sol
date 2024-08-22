// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
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
        uint256 wstonAmount = 500 * 10**18; 

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IERC20 ton = IERC20(tonAddress);
        IERC20 wston = IERC20(wstonAddress);
        IWstonSwapPool pool = IWstonSwapPool(poolAddress);

        // Approve the pool to spend TON and WSTON tokens
        ton.approve(poolAddress, tonAmount);
        wston.approve(poolAddress, wstonAmount);

        // Call addLiquidity function
        pool.addLiquidity(tonAmount, wstonAmount);

        vm.stopBroadcast();
    }
}
