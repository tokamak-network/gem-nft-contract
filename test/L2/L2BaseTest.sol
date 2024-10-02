// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { GemFactory } from "../../src/L2/GemFactory.sol";
import { Treasury } from "../../src/L2/Treasury.sol";
import { TreasuryProxy } from "../../src/L2/TreasuryProxy.sol";
import { MarketPlace } from "../../src/L2/MarketPlace.sol";
import { RandomPack } from "../../src/L2/RandomPack.sol";
import { L2StandardERC20 } from "../../src/L2/L2StandardERC20.sol";
import { MockTON } from "../../src/L2/Mock/MockTON.sol";
import { GemFactoryStorage } from "../../src/L2/GemFactoryStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { DRBCoordinatorMock } from "../../src/L2/Mock/DRBCoordinatorMock.sol";
import { DRBConsumerBase } from "../../src/L2/Randomness/DRBConsumerBase.sol";

import { Airdrop } from "../../src/L2/Airdrop.sol";

contract L2BaseTest is Test {

    using SafeERC20 for IERC20;

    uint256 public commonminingTry = 1;
    uint256 public rareminingTry = 2;
    uint256 public uniqueminingTry = 1; // for testing purpose
    uint256 public epicminingTry = 10;
    uint256 public LegendaryminingTry = 15;
    uint256 public MythicminingTry = 20;
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
    address payable user3;

    address gemfactory;
    Treasury treasury;
    TreasuryProxy treasuryProxy;
    address marketplace;
    DRBCoordinatorMock drbCoordinatorMock;
    address randomPack;
    address wston;
    address ton;
    address l1wston;
    address l1ton;
    address l2bridge;
    address airdrop;

    //DRB storage
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    uint256 public calldataSizeBytes = 2071;

    //random pack storage
    uint256 randomPackFees = 40*10**18;
    uint256 randomBeaconFees = 0.005 ether;

    event CommonGemMinted();
    function setUp() public virtual {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));
        user2 = payable(makeAddr("User2"));
        user3 = payable(makeAddr("User3"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wston = address(new L2StandardERC20(l2bridge, l1wston, "Wrapped Ston", "WSTON")); // 27 decimals
        ton = address(new MockTON(l2bridge, l1ton, "Ton", "TON")); // 18 decimals

        vm.stopPrank();
        // mint some tokens to User1 and user2

        vm.startPrank(l2bridge);
        L2StandardERC20(wston).mint(owner, 1000000 * 10 ** 27);
        L2StandardERC20(wston).mint(user1, 100000 * 10 ** 27);
        L2StandardERC20(wston).mint(user2, 100000 * 10 ** 27);
        L2StandardERC20(wston).mint(user3, 100000 * 10 ** 27);
        MockTON(ton).mint(user1, 1000000 * 10 ** 18);
        MockTON(ton).mint(user1, 100000 * 10 ** 18);
        MockTON(ton).mint(user2, 100000 * 10 ** 18);
        MockTON(ton).mint(user3, 100000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(owner);
        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);

        // deploy DRBCoordinatorMock
        drbCoordinatorMock = new DRBCoordinatorMock(
            avgL2GasUsed,
            premiumPercentage,
            flatFee,
            calldataSizeBytes
        );

        // deploy and initialize GemFactory
        gemfactory = address(new GemFactory(address(drbCoordinatorMock)));

        // deploy treasury and marketplace
        treasury = new Treasury();
        treasury.initialize(
            wston,
            ton,
            gemfactory
        );
        treasuryProxy = new TreasuryProxy();
        treasuryProxy.upgradeTo(address(treasury));
        address treasuryProxyAddress = address(treasuryProxy);

        (bool s, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("initialize(address, address, address)", wston, ton, gemfactory)
        );
        require(s, "initialize call failed");

        marketplace = address(new MarketPlace()); 

        vm.stopPrank();
        // mint some TON & TITAN WSTON to treasury

        vm.startPrank(l2bridge);
        L2StandardERC20(wston).mint(address(treasury), 100000 * 10 ** 27);
        MockTON(ton).mint(address(treasury), 100000 * 10 ** 18);

        vm.stopPrank();


        vm.startPrank(owner);

        GemFactory(gemfactory).initialize(
            wston,
            ton,
            address(treasury),
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

        GemFactory(gemfactory).setMiningTrys(
            commonminingTry,
            rareminingTry,
            uniqueminingTry,
            epicminingTry,
            LegendaryminingTry,
            MythicminingTry
        );

        MarketPlace(marketplace).initialize(
            address(treasury),
            gemfactory,
            tonFeesRate,
            wston,
            ton
        );

        GemFactory(gemfactory).setMarketPlaceAddress(marketplace);
        (bool success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("setMarketPlace(address)", marketplace)
        );
        require(success, "setMarketPlace call failed");
    
        
        // approve GemFactory to spend treasury wston
        (success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("approveGemFactory()")
        );
        require(success, "approveGemFactory call failed");
        
        (success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("wstonApproveMarketPlace()")
        );
        require(success, "wstonApproveMarketPlace call failed");

        (success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("tonApproveMarketPlace()")
        );
        require(success, "tonApproveMarketPlace call failed");

        // We deploy the RandomPack contract
        randomPack = address(new RandomPack(
            address(drbCoordinatorMock),
            ton,
            gemfactory,
            address(treasury),
            randomPackFees
        ));

        (success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("setRandomPack(address)", randomPack)
        );
        require(success, "setRandomPack call failed");
        GemFactory(gemfactory).setRandomPack(randomPack);

        // we set up the list of colors available for the GEM
        GemFactory(gemfactory).addColor("Ruby",0,0);
        GemFactory(gemfactory).addColor("Ruby/Amber",0,1);
        GemFactory(gemfactory).addColor("Amber",1,1);
        GemFactory(gemfactory).addColor("Topaz",2,2);
        GemFactory(gemfactory).addColor("Topaz/Emerald",2,3);
        GemFactory(gemfactory).addColor("Emerald/Topaz",3,2);
        GemFactory(gemfactory).addColor("Emerald",3,3);
        GemFactory(gemfactory).addColor("Emerald/Amber",3,1);
        GemFactory(gemfactory).addColor("Turquoise",4,4);
        GemFactory(gemfactory).addColor("Sapphire",5,5);
        GemFactory(gemfactory).addColor("Amethyst",6,6);
        GemFactory(gemfactory).addColor("Amethyst/Amber",6,1);
        GemFactory(gemfactory).addColor("Garnet",7,7);

        //deploying the airdrop contract
        airdrop = address(new Airdrop(
            address(treasury),
            gemfactory
        ));

        (success, ) = treasuryProxyAddress.call(
            abi.encodeWithSignature("setAirdrop(address)", airdrop)
        );
        require(success, "setAirdrop call failed");
        GemFactory(gemfactory).setAirdrop(airdrop);

        vm.stopPrank();
    }


    function testSetup() public view {
        address wstonAddress = GemFactory(gemfactory).wston();
        assert(wstonAddress == address(wston));

        address tonAddress = GemFactory(gemfactory).ton();
        assert(tonAddress == address(ton));

        address treasuryAddress = GemFactory(gemfactory).treasury();
        assert(treasuryAddress == address(treasury));

        // Check that the Treasury has approved the GemFactory to spend WSTON
        uint256 allowance = IERC20(wston).allowance(address(treasury), address(gemfactory));
        assert(allowance == type(uint256).max);
    }
}
