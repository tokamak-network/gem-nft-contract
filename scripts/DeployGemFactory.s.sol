// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/L2/GemFactory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployL2Contracts is Script {

    address public drbcoordinatormock = 0xc298211969320735d2dfb48de73a58f0E652728e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        //deploy gemFactory contract
        GemFactory gemfactory = new GemFactory(drbcoordinatormock);
        console.log("GemFactory contract deployed at:", address(gemfactory));

        vm.stopBroadcast();
    }
}
