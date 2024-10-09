// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/L2/Mock/DRBCoordinatorMock.sol";
import "../src/L2/GemFactory.sol";
import "../src/L2/Treasury.sol";
import { MarketPlace } from "../src/L2/MarketPlace.sol";
import "../src/L2/WstonSwapPool.sol";   
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployL2Contracts is Script {
    
    //swapPool storage
    address public l2wston = 0x256Cf034962292C111436F43e5d92a9EC24dcD3C;
    address public l2ton = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;
    uint256 public stakingIndex = 10**27; // = 1
    address public treasury;
    uint256 public swapPoolfeeRate = 30; //30bps = 0.3%



    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WstonSwapPool contract
        WstonSwapPool wstonSwapPool = new WstonSwapPool(l2ton, l2wston, stakingIndex, treasury, swapPoolfeeRate);

        // Log the contract address
        console.log("WstonSwapPool contract deployed at:", address(wstonSwapPool));

        vm.stopBroadcast();
    }
}
