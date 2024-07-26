// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./BaseTest.sol";

contract GemFactoryTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testSetup() public view {
        address wstonAddress = GemFactory(gemfactory).getWston();
        assert(wstonAddress == address(wston));

        address tonAddress = GemFactory(gemfactory).getTon();
        assert(tonAddress == address(ton));

        address treasuryAddress = GemFactory(gemfactory).getTreasury();
        assert(treasuryAddress == address(treasury));

        uint256 CommonMiningFeesCheck = GemFactory(gemfactory).getCommonMiningFees();
        assert(CommonMiningFeesCheck == commonMiningFees);

        uint256 RareMiningFeesCheck = GemFactory(gemfactory).getRareMiningFees();
        assert(RareMiningFeesCheck == rareMiningFees);

        uint256 UniqueMiningFeesCheck = GemFactory(gemfactory).getUniqueMiningFees();
        assert(UniqueMiningFeesCheck == uniqueMiningFees);

        // Check that the Treasury has the correct GemFactory address set
        address gemFactoryAddress = Treasury(treasury).getGemFactoryAddress();
        assert(gemFactoryAddress == address(gemfactory));

        // Check that the Treasury has approved the GemFactory to spend WSTON
        uint256 allowance = IERC20(wston).allowance(address(treasury), address(gemfactory));
        assert(allowance == type(uint256).max);
    }

    function testCreateGEM() public {
        vm.startPrank(owner);

        // Define GEM properties
        string memory color = "Red";
        uint256 value = 10 * 10 ** 27; // 10 WSTON
        bytes1 quadrants = 0x0C;
        string memory backgroundColor = "Black";
        uint256 cooldownPeriod = 3600 * 24; // 24 hours
        uint256 miningPeriod = 1200; // 20 min
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            color,
            value,
            quadrants,
            backgroundColor,
            miningPeriod,
            cooldownPeriod,
            tokenURI
        );

        // Verify GEM creation
        assert(newGemId == 0);
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactory).tokenURI(newGemId))) == keccak256(abi.encodePacked(tokenURI)));

        vm.stopPrank();
    }

    function testCreatePreminedGEMPool() public {
        vm.startPrank(owner);

        // Define GEM properties
        string[] memory colors = new string[](2);
        colors[0] = "Red";
        colors[1] = "Blue";

        uint256[] memory values = new uint256[](2);
        values[0] = 10 * 10 ** 27; // 10 WSTON
        values[1] = 150 * 10 ** 27; // 150 WSTON

        bytes1[] memory quadrants = new bytes1[](2);
        quadrants[0] = 0x0B;
        quadrants[1] = 0x22;

        string[] memory backgroundColors = new string[](2);
        backgroundColors[0] = "Black";
        backgroundColors[1] = "White";

        uint256[] memory cooldownPeriods = new uint256[](2);
        cooldownPeriods[0] = 3600 * 24; // 24 hour
        cooldownPeriods[1] = 3600 * 48; // 48 hours

        uint256[] memory miningPeriods = new uint256[](2);
        miningPeriods[0] = 1200; // 20 min
        miningPeriods[1] = 2400; // 40 min

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            colors,
            values,
            quadrants,
            backgroundColors,
            miningPeriods,
            cooldownPeriods,
            tokenURIs
        );

        // Verify GEM creation
        assert(newGemIds.length == 2);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactory).tokenURI(newGemIds[0]))) == keccak256(abi.encodePacked(tokenURIs[0])));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactory).tokenURI(newGemIds[1]))) == keccak256(abi.encodePacked(tokenURIs[1])));

        vm.stopPrank();
    }

    function testMeltGEM() public {
        vm.startPrank(owner);

        // Define GEM properties
        string memory color = "Red";
        uint256 value = 1000 * 10 ** 27;
        bytes1 quadrants = 0x34;
        string memory backgroundColor = "Black";
        uint256 miningPeriod = 3600; // 1 hour
        uint256 cooldownPeriod = 3600 * 72; // 72 hours
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            color,
            value,
            quadrants,
            backgroundColor,
            miningPeriod,
            cooldownPeriod,
            tokenURI
        );

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemId);

        // Verify GEM transfer
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        vm.stopPrank();

        // Start prank as user1 to melt the GEM
        vm.startPrank(user1);

        // Call meltGEM function
        GemFactory(gemfactory).meltGEM(newGemId);

        // Verify GEM melting
        assert(IERC20(wston).balanceOf(user1) == 2000 * 10 ** 27); // User1 should receive the WSTON (we now has 1000 + 1000 WSWTON)

        vm.stopPrank();
    }
}
