// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L2/WSTONManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployWSTONManager is Script {
        function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy your contract
        WSTONManager wstonManager = new WSTONManager();

        console.log("L2 Contract deployed at:", address(wstonManager));

        vm.stopBroadcast();
    }
}