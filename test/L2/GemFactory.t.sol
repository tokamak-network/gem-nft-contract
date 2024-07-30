// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./L2BaseTest.sol";

contract GemFactoryTest is L2BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testCreateGEM() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8 color = 0;
        uint256 value = 10 * 10 ** 27; // 10 WSTON
        uint8[4] memory quadrants = [uint8(1), uint8(2), uint8(1), uint8(2)];
        uint256 cooldownPeriod = 3600 * 24; // 24 hours
        uint256 miningPeriod = 1200; // 20 min
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            value,
            quadrants,
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
        uint8[] memory colors = new uint8[](2);
        colors[0] = 0;
        colors[1] = 1;

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.RARE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;

        uint256[] memory values = new uint256[](2);
        values[0] = 10 * 10 ** 27; // 10 WSTON
        values[1] = 150 * 10 ** 27; // 150 WSTON
        
        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [2, 3, 3, 2];
        quadrants[1] = [4, 3, 4, 4];

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
            rarities,
            colors,
            values,
            quadrants,
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
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8 color = 0;
        uint256 value = 10 * 10 ** 27; // 10 WSTON
        uint8[4] memory quadrants = [uint8(1), uint8(2), uint8(1), uint8(2)];
        uint256 cooldownPeriod = 3600 * 24; // 24 hours
        uint256 miningPeriod = 1200; // 20 min
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            value,
            quadrants,
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
        assert(IERC20(wston).balanceOf(user1) == 1010 * 10 ** 27); // User1 should receive the WSTON (we now has 1000 + 10 WSWTON)

        vm.stopPrank();
    }
}
