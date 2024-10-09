// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/L2/Mock/DRBCoordinatorMock.sol";

contract DeployDRBCoordinatorMock is Script {

    // DRB storage
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    uint256 public calldataSizeBytes = 2071;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy DRBCoordinatorMock contract
        DRBCoordinatorMock drbcoordinatormock = new DRBCoordinatorMock(avgL2GasUsed, premiumPercentage, flatFee, calldataSizeBytes);
        console.log("DRBCoordinatorMock contract deployed at:", address(drbcoordinatormock));

        vm.stopBroadcast();
    }
}
