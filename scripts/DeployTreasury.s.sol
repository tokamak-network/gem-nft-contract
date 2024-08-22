// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import { GemFactory } from "../src/L2/GemFactory.sol";
import "../src/L2/Treasury.sol";
import { MarketPlace } from "../src/L2/MarketPlace.sol";
import "../src/L2/WstonSwapPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployL2Contracts is Script {

    //DRB storage
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    uint256 public calldataSizeBytes = 2071;

    //GemFactory storage initilization
    uint256 public commonGemsValue = 10 * 10 ** 27;
    uint256 public rareGemsValue = 19 * 10 ** 27;
    uint256 public uniqueGemsValue = 53 * 10 ** 27;
    uint256 public epicGemsValue = 204 * 10 ** 27;
    uint256 public legendaryGemsValue = 605 * 10 ** 27;
    uint256 public mythicGemsValue = 4000 * 10 ** 27;

    uint256 public commonminingTry = 1;
    uint256 public rareminingTry = 2;
    uint256 public uniqueminingTry = 1;
    uint256 public epicminingTry = 10;
    uint256 public legendaryminingTry = 15;
    uint256 public mythicminingTry = 20;
    uint256 public tonFeesRate = 10; // 10%
    uint256 public miningFees = 0.01 ether;

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

    address public drbcoordinatormock = 0xc298211969320735d2dfb48de73a58f0E652728e;
    address public gemfactory=0x8a102533302587aEaf081B6D5F54C63017d81Be0;
    
    //swapPool storage
    address public l2wston = 0x256Cf034962292C111436F43e5d92a9EC24dcD3C;
    address public l2ton = 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2;
    uint256 public swapPoolfeeRate = 30; //30bps = 0.3%
    uint256 public stakingIndex = 10**27; // = 1

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Treasury treasury = new Treasury(l2wston, l2ton, gemfactory);
        console.log("Treasury contract deployed at:", address(treasury));
        MarketPlace marketplace = new MarketPlace();
        console.log("MarketPlace contract deployed at:", address(marketplace));

        GemFactory(gemfactory).initialize(
            l2wston,
            l2ton,
            address(treasury),
            commonGemsValue,
            rareGemsValue,
            uniqueGemsValue,
            epicGemsValue,
            legendaryGemsValue,
            mythicGemsValue
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

        GemFactory(gemfactory).setminingTrys(
            commonminingTry,
            rareminingTry,
            uniqueminingTry,
            epicminingTry,
            legendaryminingTry,
            mythicminingTry
        );

        marketplace.initialize(
            address(treasury),
            gemfactory,
            tonFeesRate,
            l2wston,
            l2ton
        );

        GemFactory(gemfactory).setMarketPlaceAddress(address(marketplace));
        treasury.setMarketPlace(address(marketplace));
        
        // approve GemFactory to spend treasury wston
        treasury.approveGemFactory();
        treasury.approveMarketPlace();

        vm.stopBroadcast();
    }
}
