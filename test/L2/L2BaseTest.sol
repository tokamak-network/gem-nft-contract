// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { GemFactory } from "../../src/L2/GemFactory.sol";
import { GemFactoryForging } from "../../src/L2/GemFactoryForging.sol";
import { GemFactoryMining } from "../../src/L2/GemFactoryMining.sol";
import { GemFactoryProxy } from "../../src/L2/GemFactoryProxy.sol";
import { Treasury } from "../../src/L2/Treasury.sol";
import { TreasuryProxy } from "../../src/L2/TreasuryProxy.sol";
import { MarketPlace } from "../../src/L2/MarketPlace.sol";
import { MarketPlaceProxy } from "../../src/L2/MarketPlaceProxy.sol";
import { RandomPack } from "../../src/L2/RandomPack.sol";
import { RandomPackProxy } from "../../src/L2/RandomPackProxy.sol";
import { L2StandardERC20 } from "../../src/L2/L2StandardERC20.sol";
import { MockTON } from "../../src/L2/Mock/MockTON.sol";
import { GemFactoryStorage } from "../../src/L2/GemFactoryStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { DRBCoordinatorMock } from "../../src/L2/Mock/DRBCoordinatorMock.sol";
import { DRBConsumerBase } from "../../src/L2/Randomness/DRBConsumerBase.sol";

import { Airdrop } from "../../src/L2/Airdrop.sol";
import { AirdropProxy } from "../../src/L2/AirdropProxy.sol";
import {IDRBCoordinator} from "../../src/interfaces/IDRBCoordinator.sol";

contract L2BaseTest is Test {

    using SafeERC20 for IERC20;

    uint8 public rareminingTry = 2;
    uint8 public uniqueminingTry = 1; // for testing purpose
    uint8 public epicminingTry = 10;
    uint8 public LegendaryminingTry = 15;
    uint8 public MythicminingTry = 20;

    uint256 public tonFeesRate = 10; // 10%
    uint256 public miningFees = 0.01 ether;

    uint256 public CommonGemsValue = 10 * 10 ** 27;
    uint256 public RareGemsValue = 19 * 10 ** 27;
    uint256 public UniqueGemsValue = 53 * 10 ** 27;
    uint256 public EpicGemsValue = 204 * 10 ** 27;
    uint256 public LegendaryGemsValue = 605 * 10 ** 27;
    uint256 public MythicGemsValue = 4000 * 10 ** 27;

    uint32 public RareGemsMiningPeriod = 2 weeks;
    uint32 public UniqueGemsMiningPeriod = 3 weeks;
    uint32 public EpicGemsMiningPeriod = 4 weeks;
    uint32 public LegendaryGemsMiningPeriod = 5 weeks;
    uint32 public MythicGemsMiningPeriod = 6 weeks;

    uint32 public RareGemsCooldownPeriod = 2 weeks;
    uint32 public UniqueGemsCooldownPeriod = 3 weeks;
    uint32 public EpicGemsCooldownPeriod = 4 weeks;
    uint32 public LegendaryGemsCooldownPeriod = 5 weeks;
    uint32 public MythicGemsCooldownPeriod = 6 weeks;

    address payable owner;
    address payable user1;
    address payable user2;
    address payable user3;

    GemFactory gemfactory;
    GemFactoryForging gemfactoryforging;
    GemFactoryMining gemfactorymining;
    GemFactoryProxy gemfactoryProxy;
    address gemfactoryProxyAddress;
    Treasury treasury;
    TreasuryProxy treasuryProxy;
    address payable treasuryProxyAddress;
    MarketPlace marketplace;
    MarketPlaceProxy marketplaceProxy;
    address marketplaceProxyAddress;
    DRBCoordinatorMock drbCoordinatorMock;
    Airdrop airdrop;
    AirdropProxy airdropProxy;
    address airdropProxyAddress;
    RandomPack randomPack;
    RandomPackProxy randomPackProxy;
    address payable randomPackProxyAddress;
    
    address wston;
    address ton;
    address l1wston;
    address l1ton;
    address l2bridge;
    

    //DRB storage
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    uint256 public calldataSizeBytes = 2071;

    //random pack storage
    uint256 randomPackFees = 40*10**18;
    uint256 randomBeaconFees = 0.005 ether;

    event CommonGemMinted();
    event DebugSelector(bytes4 forgeTokensSelector);
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

        // mint some tokens to User1, user2 and user3
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
        // give ETH to User1 and User2 to cover gasFees associated with using VRF functions as well as interacting with thanos
        vm.deal(user1, 1000000 ether);
        vm.deal(user2, 1000000 ether);

        // deploy DRBCoordinatorMock
        drbCoordinatorMock = new DRBCoordinatorMock(
            avgL2GasUsed,
            premiumPercentage,
            flatFee,
            calldataSizeBytes
        );

// --------------------------- GEM FACTORY DEPLOYMENT -------------------------------------------------

        // deploy GemFactory
        gemfactory = new GemFactory();
        gemfactoryforging = new GemFactoryForging();
        gemfactorymining = new GemFactoryMining();
        gemfactoryProxy = new GemFactoryProxy();
        gemfactoryProxy.upgradeTo(address(gemfactory));
        // we set the forging implementation under the proxy    
        gemfactoryProxy.setImplementation2(address(gemfactoryforging), 1, true);
        // we set the mining implementation under the proxy    
        gemfactoryProxy.setImplementation2(address(gemfactorymining), 2, true);
        
        
        // Compute the function selector for GemFactoryForging
        bytes4 forgeTokensSelector = bytes4(keccak256("forgeTokens(uint256[],uint8,uint8[2])"));
        // Create a dynamic array for the selector
        bytes4[] memory forgingSelectors = new bytes4[](1);
        forgingSelectors[0] = forgeTokensSelector;
        // Map the forgeTokens function to the GemFactoryForging implementation
        gemfactoryProxy.setSelectorImplementations2(forgingSelectors, address(gemfactoryforging));

        // Compute the function selector for GemFactoryMining
        bytes4 startMiningSelector = bytes4(keccak256("startMiningGEM(uint256)"));
        bytes4 cancelMiningSelector = bytes4(keccak256("cancelMining(uint256)"));
        bytes4 pickMinedGEMSelector = bytes4(keccak256("pickMinedGEM(uint256)"));
        bytes4 drbInitializeSelector = bytes4(keccak256("DRBInitialize(address)"));
        bytes4 rawFulfillRandomWordsSelector = bytes4(keccak256("rawFulfillRandomWords(uint256,uint256)"));
        // Create a dynamic array for the selector
        bytes4[] memory miningSelector = new bytes4[](5);
        miningSelector[0] = startMiningSelector;
        miningSelector[1] = cancelMiningSelector;
        miningSelector[2] = pickMinedGEMSelector;
        miningSelector[3] = drbInitializeSelector;
        miningSelector[4] = rawFulfillRandomWordsSelector;
        // Map the mining functions to the GemFactoryMining implementation
        gemfactoryProxy.setSelectorImplementations2(miningSelector, address(gemfactorymining));

        // Debugging: Verify the mapping
        address forgeTokenslementation = gemfactoryProxy.getSelectorImplementation2(forgeTokensSelector);
        require(forgeTokenslementation == address(gemfactoryforging), "Selector not mapped to GemFactoryForging");

        address startMiningImpl = gemfactoryProxy.getSelectorImplementation2(startMiningSelector);
        require(startMiningImpl == address(gemfactorymining), "Selector not mapped to GemFactoryMining");

        gemfactoryProxyAddress = address(gemfactoryProxy);


// ------------------------------- TREASURY DEPLOYMENT -------------------------------------------------

        // deploy and initialize treasury
        treasury = new Treasury();
        treasuryProxy = new TreasuryProxy();
        treasuryProxy.upgradeTo(address(treasury));
        treasuryProxyAddress = payable(address(treasuryProxy));
        Treasury(treasuryProxyAddress).initialize(
            wston,
            ton,
            gemfactoryProxyAddress
        );

        // deploy and initialize marketplace
        marketplace = new MarketPlace();
        marketplaceProxy = new MarketPlaceProxy();
        marketplaceProxy.upgradeTo(address(marketplace));
        marketplaceProxyAddress = address(marketplaceProxy);
        MarketPlace(marketplaceProxyAddress).initialize(
            treasuryProxyAddress,
            gemfactoryProxyAddress,
            tonFeesRate,
            wston,
            ton
        );

        vm.stopPrank();

        // mint some TON & WSTON to treasury
        vm.startPrank(l2bridge);
        L2StandardERC20(wston).mint(treasuryProxyAddress, 100000 * 10 ** 27);
        MockTON(ton).mint(treasuryProxyAddress, 100000 * 10 ** 18);

        vm.stopPrank();


        vm.startPrank(owner);
        // initialize gemfactory with newly created contract addreses
        GemFactory(gemfactoryProxyAddress).initialize(
            owner,
            wston,
            ton,
            treasuryProxyAddress
        );

        GemFactoryMining(gemfactoryProxyAddress).DRBInitialize(
            address(drbCoordinatorMock)
        );

        GemFactory(gemfactoryProxyAddress).setGemsValue(
            CommonGemsValue,
            RareGemsValue,
            UniqueGemsValue,
            EpicGemsValue,
            LegendaryGemsValue,
            MythicGemsValue
        );

        GemFactory(gemfactoryProxyAddress).setGemsMiningPeriods(
            RareGemsMiningPeriod,
            UniqueGemsMiningPeriod,
            EpicGemsMiningPeriod,
            LegendaryGemsMiningPeriod,
            MythicGemsMiningPeriod
        );

        GemFactory(gemfactoryProxyAddress).setGemsCooldownPeriods(
            RareGemsCooldownPeriod,
            UniqueGemsCooldownPeriod,
            EpicGemsCooldownPeriod,
            LegendaryGemsCooldownPeriod,
            MythicGemsCooldownPeriod
        );

        // Set mining tries
        GemFactory(gemfactoryProxyAddress).setMiningTries(
            rareminingTry,
            uniqueminingTry,
            epicminingTry,
            LegendaryminingTry,
            MythicminingTry
        );

        // set the MarketPlace contract address into the GemFactory contract
        GemFactory(gemfactoryProxyAddress).setMarketPlaceAddress(marketplaceProxyAddress);
        Treasury(treasuryProxyAddress).setMarketPlace(marketplaceProxyAddress);    

        // We deploy the RandomPack contract
        randomPack = new RandomPack();
        randomPackProxy = new RandomPackProxy();
        randomPackProxy.upgradeTo(address(randomPack));
        randomPackProxyAddress = payable(address(randomPackProxy));
        RandomPack(randomPackProxyAddress).initialize(
            address(drbCoordinatorMock),
            ton,
            gemfactoryProxyAddress,
            treasuryProxyAddress,
            randomPackFees
        );

        // Set randomPack address into the treasury contract
        Treasury(treasuryProxyAddress).setRandomPack(randomPackProxyAddress);

        // we set up the list of colors available for the GEM
        GemFactory(gemfactoryProxyAddress).addColor("Ruby",0,0);
        GemFactory(gemfactoryProxyAddress).addColor("Ruby/Amber",0,1);
        GemFactory(gemfactoryProxyAddress).addColor("Amber",1,1);
        GemFactory(gemfactoryProxyAddress).addColor("Topaz",2,2);
        GemFactory(gemfactoryProxyAddress).addColor("Topaz/Emerald",2,3);
        GemFactory(gemfactoryProxyAddress).addColor("Emerald/Topaz",3,2);
        GemFactory(gemfactoryProxyAddress).addColor("Emerald",3,3);
        GemFactory(gemfactoryProxyAddress).addColor("Emerald/Amber",3,1);
        GemFactory(gemfactoryProxyAddress).addColor("Turquoise",4,4);
        GemFactory(gemfactoryProxyAddress).addColor("Sapphire",5,5);
        GemFactory(gemfactoryProxyAddress).addColor("Amethyst",6,6);
        GemFactory(gemfactoryProxyAddress).addColor("Amethyst/Amber",6,1);
        GemFactory(gemfactoryProxyAddress).addColor("Garnet",7,7);

        //deploying and initializing the airdrop contract
        airdrop = new Airdrop();
        airdropProxy = new AirdropProxy();
        airdropProxy.upgradeTo(address(airdrop));
        airdropProxyAddress = address(airdropProxy);
        Airdrop(airdropProxyAddress).initialize(treasuryProxyAddress, gemfactoryProxyAddress);

        // set the airdrop address in treasury and gemfactory
        Treasury(treasuryProxyAddress).setAirdrop(airdropProxyAddress);
        GemFactory(gemfactoryProxyAddress).setAirdrop(airdropProxyAddress);

        vm.stopPrank();
    }


    function testSetup() public view {
        address wstonAddress = GemFactory(gemfactoryProxyAddress).getWstonAddress();
        assert(wstonAddress == address(wston));

        address tonAddress = GemFactory(gemfactoryProxyAddress).getTonAddress();
        assert(tonAddress == address(ton));

        address treasuryAddress = GemFactory(gemfactoryProxyAddress).getTreasuryAddress();
        assert(treasuryAddress == treasuryProxyAddress);
    }
}
