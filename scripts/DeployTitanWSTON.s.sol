// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/L2/Mock/L2StandardERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployTitanWSTON is Script {
    
    address public l1Token=0x17Ddb5CEaE35A40a520c4DcF1f70409BE9a25406;
    address public l2Bridge=0x4200000000000000000000000000000000000010;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the WrappedStakedTON contract
        L2StandardERC20 titanWston = new L2StandardERC20(l2Bridge, l1Token, "Titan Wston", "TITANWSTON");

        // Log the contract address
        console.log("Titan WSTON deployed at:", address(titanWston));

        vm.stopBroadcast();
    }
}