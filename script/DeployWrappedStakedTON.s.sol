// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L1/L1WrappedStakedTON.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployWrappedStakedTON is Script {
    address depositManager = 0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F;
    address seigManager = 0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7;
    address l1wton = 0x79E0d92670106c85E9067b56B8F674340dCa0Bbd;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 amount = 100 * 10**27; // Example amount to approve and deposit
        uint256 layer2Index = 0; // Example Layer2 index

        vm.startBroadcast(deployerPrivateKey);

        // Create a memory array to hold the Layer2 struct
        L1WrappedStakedTONStorage.Layer2[] memory layer2s = new L1WrappedStakedTONStorage.Layer2[](1);
        layer2s[0] = L1WrappedStakedTONStorage.Layer2(
            0xCBeF7Cc221c04AD2E68e623613cc5d33b0fE1599,
            address(0),
            address(0),
            address(0),
            address(0)
        );

        // Deploy the WrappedStakedTON contract
        L1WrappedStakedTON wston = new L1WrappedStakedTON(layer2s, depositManager, seigManager, l1wton);

        // Log the contract address
        console.log("WrappedStakedTON deployed at:", address(wston));

        // Approve the WrappedStakedTON contract to spend your tokens
        IERC20(l1wton).approve(address(wston), amount);

        // Call the depositAndGetWSWTON function
        wston.depositAndGetWSTON(amount, layer2Index);

        vm.stopBroadcast();
    }
}
