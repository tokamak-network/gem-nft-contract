// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../../src/L2/Swap/WstonSwap.sol";
import "../../src/L2/Swap/IV3SwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WstonSwapTest is Test {
    WstonSwap public wstonSwap;
    IERC20 public ton;
    IERC20 public wston;

    uint256 mainnetFork;

    address public tonAddress = address(0x1);
    address public wstonAddress = address(0x2);
    address public swapRouter = address(0x3);
    address public user = address(0x4);

    function setUp() public {

        string memory MAINNET_RPC_URL = vm.envString("TIITAN_SEPOLIA_RPC_URL");
        mainnetFork = vm.createFork(MAINNET_RPC_URL);

        // Deploy mock contracts
        ton = IERC20(tonAddress);
        wston = IERC20(wstonAddress);

        // Deploy the WstonSwap contract
        wstonSwap = new WstonSwap(swapRouter, tonAddress, wstonAddress);

        // Label addresses for easier debugging
        vm.label(tonAddress, "TON");
        vm.label(wstonAddress, "WSTON");
        vm.label(swapRouter, "SwapRouter");
        vm.label(user, "User");
    }

    function testForkId() public view {
        assert(mainnetFork != 0);
    }

    function testSelectFork() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testForkBlockNumber() public {
        vm.selectFork(mainnetFork);
        vm.rollFork(15000000);
        assertEq(block.number, 15000000);
    }

    
}
