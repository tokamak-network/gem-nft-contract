// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { GemFactory } from "../../src/L2/GemFactory.sol";
import { Treasury } from "../../src/L2/Treasury.sol";
import { MarketPlace } from "../../src/L2/MarketPlace.sol";
import { ERC20Mock } from "../../src/L2/ERC20Mock.sol";
import { GemFactoryStorage } from "../../src/L2/GemFactoryStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseTest is Test {

    using SafeERC20 for IERC20;

    uint256 public commonMiningFees = 10 * 10 ** 18;
    uint256 public rareMiningFees = 20 * 10 ** 18;
    uint256 public uniqueMiningFees = 40 * 10 ** 18;
    uint256 public tonFeesRate = 10; // 10%

    address payable owner;
    address payable user1;
    address payable user2;
    address payable coordinator;

    address gemfactory;
    address treasury;
    address marketplace;
    address wston;
    address ton;

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wston = address(new ERC20Mock("Wrapped Ston", "WSTON", 27)); // 27 decimals
        ton = address(new ERC20Mock("Ton", "TON", 18)); // 18 decimals

        // Transfer some tokens to User1
        IERC20(wston).transfer(user1, 1000 * 10 ** 27);
        IERC20(wston).transfer(user2, 1000 * 10 ** 27);
        IERC20(ton).transfer(user1, 1000 * 10 ** 18);
        IERC20(ton).transfer(user2, 1000 * 10 ** 18);

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        // deploy treasury and marketplace
        treasury = address(new Treasury(coordinator, wston, ton));
        marketplace = address(new MarketPlace(coordinator));

        // transfer some TON & TITAN WSTON to treasury
        IERC20(wston).transfer(treasury, 100000 * 10 ** 27);
        IERC20(ton).transfer(treasury, 100000 * 10 ** 18);

        // deploy and initialize GemFactory
        gemfactory = address(new GemFactory(coordinator));

        // Grant admin role to owner
        GemFactory(gemfactory).grantRole(GemFactory(gemfactory).DEFAULT_ADMIN_ROLE(), owner);

        GemFactory(gemfactory).initialize(
            wston,
            ton,
            treasury,
            commonMiningFees,
            rareMiningFees,
            uniqueMiningFees
        );

        MarketPlace(marketplace).initialize(
            treasury,
            address(gemfactory),
            tonFeesRate,
            wston,
            ton
        );

        GemFactory(gemfactory).setMarketPlaceAddress(marketplace);
        Treasury(treasury).setGemFactory(gemfactory);
        Treasury(treasury).setMarketPlace(marketplace);
        
        // approve GemFactory to spend treasury wston
        Treasury(treasury).approveGemFactory();
        Treasury(treasury).approveMarketPlace();

        vm.stopPrank();
    }
}
