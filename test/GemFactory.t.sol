// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { GemFactory } from "../src/L2/GemFactory.sol";
import { Treasury } from "../src/L2/Treasury.sol";
import { MockERC20 } from "../src/L2/MockERC20.sol";
import { GemFactoryStorage } from "../src/L2/GemFactoryStorage.sol";

contract GemFactoryTest is Test {

    uint256 public baseMiningFees = 10 * 10 ** 18;
    uint256 public commonMiningFees = 20 * 10 ** 18;
    uint256 public uncommonMiningFees = 40 * 10 ** 18;
    uint256 public rareMiningFees = 80 * 10 ** 18;

    address payable owner;
    address payable user1;
    address payable coordinator;

    GemFactory gemfactory;
    Treasury treasury;
    MockERC20 wston;
    MockERC20 ton;

    function setUp() public {
        owner = payable(makeAddr("Owner"));
        user1 = payable(makeAddr("User1"));

        vm.startPrank(owner);
        vm.warp(1632934800);

        wston = new MockERC20("TITAN WSWTON", "WSTON", 200000 * 10 ** 27);
        ton = new MockERC20("TITAN TON", "TON", 200000 * 10 ** 18);

        // Transfer some tokens to User1
        wston.transfer(user1, 1000 * 10 ** 27);
        ton.transfer(user1, 1000 * 10 ** 18);

        // give ETH to User1 to cover gasFees associated with using VRF functions
        vm.deal(user1, 100 ether);

        // deploy treasury and transfer some TON & TITAN WSTON
        treasury = new Treasury(coordinator, address(wston), address(ton));
        wston.transfer(address(treasury), 100000 * 10 ** 27);
        ton.transfer(address(treasury), 100000 * 10 ** 18);

        // deploy and initialize GemFactory
        gemfactory = new GemFactory(coordinator);

        // Grant admin role to owner
        gemfactory.grantRole(gemfactory.DEFAULT_ADMIN_ROLE(), owner);

        gemfactory.initialize(
            address(wston),
            address(ton),
            address(treasury),
            baseMiningFees,
            commonMiningFees,
            uncommonMiningFees,
            rareMiningFees
        );
        treasury.setGemFactory(address(gemfactory));
        
        // approve GemFactory to spend treasury wston
        treasury.approveGemFactory(100000 * 10 ** 27);

        vm.stopPrank();
    }

    function testSetup() public view {

        address wstonAddress = gemfactory.getWston();
        assert(wstonAddress == address(wston));

        address tonAddress = gemfactory.getTon();
        assert(tonAddress == address(ton));

        address treasuryAddress = gemfactory.getTreasury();
        assert(treasuryAddress == address(treasury));

        uint256 baseMiningFeesCheck = gemfactory.getBaseMiningFees();
        assert(baseMiningFeesCheck == baseMiningFees);

        uint256 commonMiningFeesCheck = gemfactory.getCommonMiningFees();
        assert(commonMiningFeesCheck == commonMiningFees);

        uint256 uncommonMiningFeesCheck = gemfactory.getUncommonMiningFees();
        assert(uncommonMiningFeesCheck == uncommonMiningFees);

        uint256 rareMiningFeesCheck = gemfactory.getRareMiningFees();
        assert(rareMiningFeesCheck == rareMiningFees);

        // Check that the Treasury has the correct GemFactory address set
        address gemFactoryAddress = treasury.getGemFactoryAddress();
        assert(gemFactoryAddress == address(gemfactory));

        // Check that the Treasury has approved the GemFactory to spend WSTON
        uint256 allowance = wston.allowance(address(treasury), address(gemfactory));
        assert(allowance == 100000 * 10 ** 27);
    }

    function testCreateGEM() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.BASE;
        string memory color = "Red";
        uint128 value = 100 * 10 ** 27;
        bytes2 quadrants = 0x1111;
        string memory colorStyle = "Solid";
        string memory backgroundColor = "Black";
        string memory backgroundColorStyle = "Gradient";
        uint256 cooldownPeriod = 3600 * 24; // 24 hours
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function
        uint256 newGemId = treasury.createPreminedGEM(
            rarity,
            color,
            value,
            quadrants,
            colorStyle,
            backgroundColor,
            backgroundColorStyle,
            cooldownPeriod,
            tokenURI
        );

        // Verify GEM creation
        assert(newGemId == 0);
        assert(gemfactory.ownerOf(newGemId) == address(treasury));
        assert(keccak256(abi.encodePacked(gemfactory.tokenURI(newGemId))) == keccak256(abi.encodePacked(tokenURI)));

        vm.stopPrank();
    }
}
