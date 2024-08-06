// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { L1WrappedStakedTON } from "../../src/L1/L1WrappedStakedTON.sol";
import { L1WrappedStakedTONStorage } from "../../src/L1/L1WrappedStakedTONStorage.sol";

import { MockL2WSTON } from "../../src/L2/MockL2WSTON.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract L1BaseTest is Test {

    using SafeERC20 for IERC20;

    address payable owner;
    address payable user1;
    address payable user2;

    address l1wrappedstakedton;
    address l1wton;
    address ton;

    address depositManager = 0x90ffcc7F168DceDBEF1Cb6c6eB00cA73F922956F;
    address seigManager = 0x2320542ae933FbAdf8f5B97cA348c7CeDA90fAd7;
    address titanL1StandardBridge = 0x1F032B938125f9bE411801fb127785430E7b3971;
    address stakingLayer2Address = 0xCBeF7Cc221c04AD2E68e623613cc5d33b0fE1599;

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        l1wton = address(new MockL2WSTON("Wrapped Ton", "WTON", 27)); // 27 decimals
        ton = address(new MockL2WSTON("Ton", "TON", 18)); // 18 decimals

        // Transfer some tokens to User1
        IERC20(l1wton).transfer(user1, 1000 * 10 ** 27);
        IERC20(l1wton).transfer(user2, 1000 * 10 ** 27);
        IERC20(ton).transfer(user1, 1000 * 10 ** 18);
        IERC20(ton).transfer(user2, 1000 * 10 ** 18);

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        // Create a memory array to hold the Layer2 struct
        L1WrappedStakedTONStorage.Layer2[] memory layer2s = new L1WrappedStakedTONStorage.Layer2[](1);
        layer2s[0] = L1WrappedStakedTONStorage.Layer2(
            stakingLayer2Address,
            titanL1StandardBridge,
            address(0),
            address(0),
            0,
            block.timestamp
        );

        uint256 minDepositAmount = 100 * 10**27;


        // deploy and initialize GemFactory
        l1wrappedstakedton = address(new L1WrappedStakedTON(layer2s, minDepositAmount, depositManager, seigManager, l1wton));

        vm.stopPrank();
    }


    function testSetup() public view {
        address l1wtonCheck = L1WrappedStakedTON(l1wrappedstakedton).l1wton();
        assert(l1wtonCheck == l1wton);

        address seigManagerCheck =  L1WrappedStakedTON(l1wrappedstakedton).seigManager();
        assert(seigManagerCheck == seigManager);

    }
}
