// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L2/WSTONVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployL2WSTONVault is Script {

    /*

    address wston = 0x35D48A789904E9b15705977192e5d95e2aF7f1D3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WrappedStakedTON contract
        WSTONVault l2wstonvault = new WSTONVault(wston);

        // Log the contract address
        console.log("L2WSTONVault deployed at:", address(l2wstonvault));

        vm.stopBroadcast();
    }
    */
}
