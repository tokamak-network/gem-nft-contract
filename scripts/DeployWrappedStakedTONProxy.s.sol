// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L1/L1WrappedStakedTONProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployWrappedStakedTONProxy is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WrappedStakedTON contract
        L1WrappedStakedTONProxy wstonProxy = new L1WrappedStakedTONProxy();

        // Log the contract address
        console.log("WrappedStakedTONProxy deployed at:", address(wstonProxy));

        vm.stopBroadcast();
    }
}