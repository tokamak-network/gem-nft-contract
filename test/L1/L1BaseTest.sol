// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { L1WrappedStakedTONFactory } from "../../src/L1/L1WrappedStakedTONFactory.sol";
import { L1WrappedStakedTON } from "../../src/L1/L1WrappedStakedTON.sol";


import { DepositManager } from "../../src/L1/Mock/DepositManager.sol";
import { SeigManager } from "../../src/L1/Mock/SeigManager.sol";
import { MockWTON } from "../../src/L1/Mock/MockWTON.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract L1BaseTest is Test {
    using SafeERC20 for IERC20;

    address payable owner;
    address payable user1;
    address payable user2;

    address l1wrappedstakedton;
    address l1wrappedstakedtonFactory;
    address wton;

    address depositManager;
    address seigManager;
    address stakingLayer2Address = 0xCBeF7Cc221c04AD2E68e623613cc5d33b0fE1599;

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wton = address(new MockWTON("Wrapped Ton", "WTON", 27)); // 27 decimals

        // Transfer some tokens to User1
        IERC20(wton).transfer(user1, 10000 * 10 ** 27); // 10000 WTON
        IERC20(wton).transfer(user2, 10000 * 10 ** 27); // 10000 WTON

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        uint256 delay = 1209600;

        depositManager = address(new DepositManager(wton, delay));
        seigManager = address(new SeigManager(depositManager));
        l1wrappedstakedtonFactory = address(new L1WrappedStakedTONFactory(wton));
        
        DepositManager(depositManager).setSeigManager(seigManager);

        // deploy and initialize Wrapped Staked TON
        l1wrappedstakedton = L1WrappedStakedTONFactory(l1wrappedstakedtonFactory).createWSTONToken(
            stakingLayer2Address,
            depositManager,
            seigManager,
            "Titan Wrapped Staked TON",
            "Titan WSTON"
        );

        vm.stopPrank();
    }


    function testSetup() public view {
        address l1wtonCheck = L1WrappedStakedTON(l1wrappedstakedton).depositManager();
        assert(l1wtonCheck == depositManager);

        address seigManagerCheck =  L1WrappedStakedTON(l1wrappedstakedton).seigManager();
        assert(seigManagerCheck == seigManager);

    }
}
