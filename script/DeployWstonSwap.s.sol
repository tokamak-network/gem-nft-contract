// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L2/Swap/WstonSwap.sol";
import { IV3SwapRouter } from '../src/L2/Swap/IV3SwapRouter.sol';


contract DeployWstonSwap is Script {
    
    address swapRouter = 0x709C67488edC9fd8BdAf267BFA276B49CD62c217;
    address ton = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;
    address wston = address(0);


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WrappedStakedTON contract
        WstonSwap wstonSwap = new WstonSwap(swapRouter, wston, ton);

        // Log the contract address
        console.log("Wston Swap deployed at:", address(wstonSwap));

        vm.stopBroadcast();
    }
}
