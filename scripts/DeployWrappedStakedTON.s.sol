// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L1/L1WrappedStakedTON.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployWrappedStakedTON is Script {
    
    address depositManager = 0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F;
    address seigManager = 0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7;
    address l1wton = 0x79E0d92670106c85E9067b56B8F674340dCa0Bbd;
    address titanL1StandardBridge = 0x1F032B938125f9bE411801fb127785430E7b3971;
    address stakingLayer2Address = 0xCBeF7Cc221c04AD2E68e623613cc5d33b0fE1599;
    string name = "Titan Wston";
    string symbol = "WSTON";

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WrappedStakedTON contract
        L1WrappedStakedTON wston = new L1WrappedStakedTON(stakingLayer2Address, l1wton, depositManager, seigManager, name, symbol);

        // Log the contract address
        console.log("WrappedStakedTON deployed at:", address(wston));

        vm.stopBroadcast();
    }
}