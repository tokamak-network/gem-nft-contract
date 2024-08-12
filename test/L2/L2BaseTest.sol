// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { GemFactory } from "../../src/L2/GemFactory.sol";
import { Treasury } from "../../src/L2/Treasury.sol";
import { MarketPlace } from "../../src/L2/MarketPlace.sol";
import { MockL2WSTON } from "../../src/L2/Mock/MockL2WSTON.sol";
import { GemFactoryStorage } from "../../src/L2/GemFactoryStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { DRBCoordinatorMock } from "../../src/L2/Mock/DRBCoordinatorMock.sol";
import { DRBConsumerBase } from "../../src/L2/Randomness/DRBConsumerBase.sol";

contract L2BaseTest is Test {

    using SafeERC20 for IERC20;

    uint256 public commonMiningPower = 1;
    uint256 public rareMiningPower = 2;
    uint256 public uniqueMiningPower = 1;
    uint256 public epicMiningPower = 10;
    uint256 public LegendaryMiningPower = 15;
    uint256 public MythicMiningPower = 20;
    uint256 public tonFeesRate = 10; // 10%
    uint256 public miningFees = 0.01 ether;

    uint256 public CommonGemsValue = 10 * 10 ** 27;
    uint256 public RareGemsValue = 19 * 10 ** 27;
    uint256 public UniqueGemsValue = 53 * 10 ** 27;
    uint256 public EpicGemsValue = 204 * 10 ** 27;
    uint256 public LegendaryGemsValue = 605 * 10 ** 27;
    uint256 public MythicGemsValue = 4000 * 10 ** 27;

    uint256 public CommonGemsMiningPeriod = 1 weeks;
    uint256 public RareGemsMiningPeriod = 2 weeks;
    uint256 public UniqueGemsMiningPeriod = 3 weeks;
    uint256 public EpicGemsMiningPeriod = 4 weeks;
    uint256 public LegendaryGemsMiningPeriod = 5 weeks;
    uint256 public MythicGemsMiningPeriod = 6 weeks;

    uint256 public CommonGemsCooldownPeriod = 1 weeks;
    uint256 public RareGemsCooldownPeriod = 2 weeks;
    uint256 public UniqueGemsCooldownPeriod = 3 weeks;
    uint256 public EpicGemsCooldownPeriod = 4 weeks;
    uint256 public LegendaryGemsCooldownPeriod = 5 weeks;
    uint256 public MythicGemsCooldownPeriod = 6 weeks;

    address payable owner;
    address payable user1;
    address payable user2;

    address gemfactory;
    address treasury;
    address marketplace;
    address wston;
    address ton;

    //DRB storage
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    uint256 public calldataSizeBytes = 2071;

    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wston = address(new MockL2WSTON("Wrapped Ston", "WSTON", 27)); // 27 decimals
        ton = address(new MockL2WSTON("Ton", "TON", 18)); // 18 decimals

        // Transfer some tokens to User1
        IERC20(wston).transfer(user1, 1000 * 10 ** 27);
        IERC20(wston).transfer(user2, 1000 * 10 ** 27);
        IERC20(ton).transfer(user1, 1000 * 10 ** 18);
        IERC20(ton).transfer(user2, 1000 * 10 ** 18);

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);

        // deploy DRBCoordinatorMock
        DRBCoordinatorMock drbCoordinatorMock = new DRBCoordinatorMock(
            avgL2GasUsed,
            premiumPercentage,
            flatFee,
            calldataSizeBytes
        );

        // deploy treasury and marketplace
        treasury = address(new Treasury(address(drbCoordinatorMock), wston, ton));
        marketplace = address(new MarketPlace(address(drbCoordinatorMock)));

        // transfer some TON & TITAN WSTON to treasury
        IERC20(wston).transfer(treasury, 100000 * 10 ** 27);
        IERC20(ton).transfer(treasury, 100000 * 10 ** 18);

        // deploy and initialize GemFactory
        gemfactory = address(new GemFactory(address(drbCoordinatorMock)));

        // Grant admin role to owner
        GemFactory(gemfactory).grantRole(GemFactory(gemfactory).DEFAULT_ADMIN_ROLE(), owner);

        GemFactory(gemfactory).initialize(
            wston,
            ton,
            treasury,
            CommonGemsValue,
            RareGemsValue,
            UniqueGemsValue,
            EpicGemsValue,
            LegendaryGemsValue,
            MythicGemsValue
        );

        GemFactory(gemfactory).setGemsMiningPeriods(
            CommonGemsMiningPeriod,
            RareGemsMiningPeriod,
            UniqueGemsMiningPeriod,
            EpicGemsMiningPeriod,
            LegendaryGemsMiningPeriod,
            MythicGemsMiningPeriod
        );

        GemFactory(gemfactory).setGemsCooldownPeriods(
            CommonGemsCooldownPeriod,
            RareGemsCooldownPeriod,
            UniqueGemsCooldownPeriod,
            EpicGemsCooldownPeriod,
            LegendaryGemsCooldownPeriod,
            MythicGemsCooldownPeriod
        );

        GemFactory(gemfactory).setMiningPowers(
            commonMiningPower,
            rareMiningPower,
            uniqueMiningPower,
            epicMiningPower,
            LegendaryMiningPower,
            MythicMiningPower
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


    function testSetup() public view {
        address wstonAddress = GemFactory(gemfactory).getWston();
        assert(wstonAddress == address(wston));

        address tonAddress = GemFactory(gemfactory).getTon();
        assert(tonAddress == address(ton));

        address treasuryAddress = GemFactory(gemfactory).getTreasury();
        assert(treasuryAddress == address(treasury));

        // Check that the Treasury has the correct GemFactory address set
        address gemFactoryAddress = Treasury(treasury).getGemFactoryAddress();
        assert(gemFactoryAddress == address(gemfactory));

        // Check that the Treasury has approved the GemFactory to spend WSTON
        uint256 allowance = IERC20(wston).allowance(address(treasury), address(gemfactory));
        assert(allowance == type(uint256).max);
    }
}
