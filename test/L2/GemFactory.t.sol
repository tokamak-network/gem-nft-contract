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
        uint8[2] memory color = [0,0];
        uint256 stakingIndex = 1;
        uint8[4] memory quadrants = [1, 2, 1, 1];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            stakingIndex,
            quadrants,
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
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0,0];
        colors[1] = [1,1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.RARE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;

        uint256[] memory stakingIndexes = new uint256[](2);
        stakingIndexes[0] = 1; 
        stakingIndexes[1] = 1; 
        
        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [2, 3, 3, 2];
        quadrants[1] = [4, 3, 4, 3];

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            stakingIndexes,
            quadrants,
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
        uint8[2] memory color = [0,0];
        uint256 stakingIndex = 1;
        uint8[4] memory quadrants = [1,2,1,1];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            stakingIndex,
            quadrants,
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

    function testForgeGem() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.COMMON;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;

        uint256[] memory stakingIndexes = new uint256[](2);
        stakingIndexes[0] = 1;
        stakingIndexes[1] = 1;

        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [1, 2, 1, 1];
        quadrants[1] = [1, 1, 2, 1];

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            stakingIndexes,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[1]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == user1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];

        uint8[2] memory color = [0, 1];

        uint256 newGemId = GemFactory(gemfactory).forgeTokens(tokenIds, 1, GemFactoryStorage.Rarity.COMMON, color);

        // Verify the new gem is created and owned by user1
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        // Verify the new gem properties
        GemFactoryStorage.Gem memory newGem = GemFactory(gemfactory).getGem(newGemId);
        assert(newGem.rarity == GemFactoryStorage.Rarity.RARE);
        assert(newGem.color[0] == color[0] && newGem.color[1] == color[1]);
        assert(newGem.stakingIndex == 1);
        assert(newGem.miningPeriod == RareGemsMiningPeriod);
        assert(newGem.gemCooldownPeriod == block.timestamp + RareGemsCooldownPeriod);

        // Verify the new gem quadrants
        assert(newGem.quadrants[0] == 2);
        assert(newGem.quadrants[1] == 3);
        assert(newGem.quadrants[2] == 3);
        assert(newGem.quadrants[3] == 2);

        vm.stopPrank();
    }

}
