// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
        uint8[4] memory quadrants = [1, 2, 1, 1];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
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
        uint8[4] memory quadrants = [1,2,1,1];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
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
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        // Call meltGEM function
        GemFactory(gemfactory).meltGEM(newGemId);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        uint256 gemValue = GemFactory(gemfactory).getCommonValue();
        // Verify GEM melting
        assert(balanceAfter == balanceBefore + gemValue); // User1 should receive the WSTON (we now has 1000 + 10 WSWTON)

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

        uint256 newGemId = GemFactory(gemfactory).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        // Verify the new gem properties
        GemFactoryStorage.Gem memory newGem = GemFactory(gemfactory).getGem(newGemId);
        assert(newGem.rarity == GemFactoryStorage.Rarity.RARE);
        assert(newGem.color[0] == color[0] && newGem.color[1] == color[1]);
        assert(newGem.miningPeriod == RareGemsMiningPeriod);
        assert(newGem.gemCooldownPeriod == block.timestamp + RareGemsCooldownPeriod);

        // Verify the new gem quadrants
        assert(newGem.quadrants[0] == 2);
        assert(newGem.quadrants[1] == 3);
        assert(newGem.quadrants[2] == 3);
        assert(newGem.quadrants[3] == 2);

        vm.stopPrank();
    }

    function testForgeUniqueGems() public {
         vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](4);
        colors[0] = [0, 0];
        colors[1] = [1, 1];
        colors[2] = [3, 1];
        colors[3] = [2, 2];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](4);
        rarities[0] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[2] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[3] = GemFactoryStorage.Rarity.UNIQUE;

        uint8[4][] memory quadrants = new uint8[4][](4);
        quadrants[0] = [4, 3, 3, 3];
        quadrants[1] = [4, 4, 4, 3];
        quadrants[2] = [3, 4, 3, 4];
        quadrants[3] = [3, 3, 4, 3];

        string[] memory tokenURIs = new string[](4);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[1]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[2]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[3]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == user1);

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        tokenIds[2] = newGemIds[2];
        tokenIds[3] = newGemIds[3];

        uint8[2] memory color = [1, 3];

        uint256 newGemId = GemFactory(gemfactory).forgeTokens(tokenIds, GemFactoryStorage.Rarity.UNIQUE, color);

        // Verify the new gem properties
        GemFactoryStorage.Gem memory newGem = GemFactory(gemfactory).getGem(newGemId);
        assert(newGem.rarity == GemFactoryStorage.Rarity.EPIC);
        assert(newGem.color[0] == color[0] && newGem.color[1] == color[1]);
        assert(newGem.miningPeriod == EpicGemsMiningPeriod);
        assert(newGem.gemCooldownPeriod == block.timestamp + EpicGemsCooldownPeriod);

        // Verify the new gem quadrants
        assert(newGem.quadrants[0] == 4);
        assert(newGem.quadrants[1] == 4);
        assert(newGem.quadrants[2] == 4);
        assert(newGem.quadrants[3] == 5);

        vm.stopPrank();
    }

    function testForgeGemRevertsIfRaritiesNotSame() public {
        vm.startPrank(owner);

        // Define GEM properties with different rarities
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.COMMON;
        rarities[1] = GemFactoryStorage.Rarity.RARE;

        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [1, 2, 1, 1];
        quadrants[1] = [2, 2, 2, 3];

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));

        // Transfer the GEMs to user1
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

        // Expect the transaction to revert with the error message "wrong rarity Gems"
        vm.expectRevert("wrong rarity Gems");
        GemFactory(gemfactory).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        vm.stopPrank();
    }

    function testForgeGemRevertsIfColorNotCorrect() public {
        vm.startPrank(owner);

        // Define GEM properties with the same rarity and valid colors
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.COMMON;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;

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
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));

        // Transfer the GEMs to user1
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

        // Define an invalid color that cannot be obtained from the input tokens
        uint8[2] memory invalidColor = [2, 3];

        // Expect the transaction to revert with the error message "this color can't be obtained"
        vm.expectRevert("this color can't be obtained");
        GemFactory(gemfactory).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, invalidColor);

        vm.stopPrank();
    }

    function testForgeGemRevertsIfGemsNumberNotCorrect() public {
        vm.startPrank(owner);

        // Define GEM properties with the same rarity and valid colors
        uint8[2][] memory colors = new uint8[2][](4);
        colors[0] = [0, 0]; // solid Ruby
        colors[1] = [3, 2]; // gradient Emerald/Topaz
        colors[2] = [2, 2]; // solid Topaz
        colors[3] = [6, 1]; // gradient Amethyst/Amber

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](4);
        rarities[0] = GemFactoryStorage.Rarity.EPIC;
        rarities[1] = GemFactoryStorage.Rarity.EPIC;
        rarities[2] = GemFactoryStorage.Rarity.EPIC;
        rarities[3] = GemFactoryStorage.Rarity.EPIC;

        uint8[4][] memory quadrants = new uint8[4][](4);
        quadrants[0] = [4, 5, 5, 5]; // epic quadrants
        quadrants[1] = [5, 4, 4, 5]; // epic quadrants
        quadrants[2] = [4, 4, 4, 5]; // epic quadrants
        quadrants[3] = [4, 4, 5, 4]; // epic quadrants

        string[] memory tokenURIs = new string[](4);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM creation
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));

        // Transfer the GEMs to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[1]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[2]);
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[3]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == user1);

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        tokenIds[2] = newGemIds[2];
        tokenIds[3] = newGemIds[3];

        uint8[2] memory color = [2, 3];

        // Expect the transaction to revert with the error message "wrong number of Gems to be forged"
        vm.expectRevert("wrong number of Gems to be forged");
        GemFactory(gemfactory).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        vm.stopPrank();
    }

    function testStartMiningGEM() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemId);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);

        vm.stopPrank();

        // Expect the transaction to succeed
        vm.prank(user1);
        bool result = GemFactory(gemfactory).startMiningGEM(newGemId);
        assert(result == true);
    }

    function testStartMiningGEMRevertsIfCooldownNotElapsed() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemId);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        // Expect the transaction to revert with the error message "Gem cooldown period has not elapsed"
        vm.expectRevert("Gem cooldown period has not elapsed");
        GemFactory(gemfactory).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    function testStartMiningGEMRevertsIfGemLocked() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemId);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);

        // putGemFor sale before calling startMining to ensure Gem is locked
        uint256 gemPrice = 1500 * 10 ** 27;
        GemFactory(gemfactory).approve(address(marketplace), newGemId);
        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);

        vm.stopPrank();

        vm.prank(user1);

        // Expect the transaction to revert with the error message "Gem is listed for sale or already mining"
        vm.expectRevert("Gem is listed for sale or already mining");
        GemFactory(gemfactory).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    function testStartMiningGEMRevertsIfNotOwner() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemId);

        vm.stopPrank();

        vm.startPrank(user2); // Different user

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        vm.stopPrank();

        vm.prank(user2);

        // Expect the transaction to revert with the error message "GEMIndexToOwner[_tokenId] == msg.sender"
        vm.expectRevert("not gem owner");
        GemFactory(gemfactory).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    function testStartMiningGEMRandomGem() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](5);
        colors[0] = [0, 1];
        colors[1] = [1, 1];
        colors[2] = [1, 1];
        colors[3] = [1, 1];
        colors[4] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](5);
        rarities[0] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;
        rarities[2] = GemFactoryStorage.Rarity.COMMON;
        rarities[3] = GemFactoryStorage.Rarity.RARE;
        rarities[4] = GemFactoryStorage.Rarity.RARE;

        uint8[4][] memory quadrants = new uint8[4][](5);
        quadrants[0] = [3, 3, 4, 4];
        quadrants[1] = [1, 2, 2, 1];
        quadrants[2] = [1, 1, 2, 2];
        quadrants[3] = [2, 3, 2, 3];
        quadrants[4] = [2, 3, 2, 3];

        string[] memory tokenURIs = new string[](5);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";
        tokenURIs[4] = "https://example.com/token/5";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[4]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);
        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);
        GemFactory(gemfactory).pickMinedGEM{value: miningFees}(newGemIds[0]);
        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactory).getRandomRequest(0);

        assert(randomRequest.fulfilled == false);
        assert(randomRequest.requested == true);
        assert(randomRequest.requester == user1);

        vm.stopPrank();

    }

    function testRandomBeaconMiningGem() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](5);
        colors[0] = [0, 1];
        colors[1] = [1, 1];
        colors[2] = [1, 1];
        colors[3] = [1, 1];
        colors[4] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](5);
        rarities[0] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;
        rarities[2] = GemFactoryStorage.Rarity.COMMON;
        rarities[3] = GemFactoryStorage.Rarity.RARE;
        rarities[4] = GemFactoryStorage.Rarity.RARE;

        uint8[4][] memory quadrants = new uint8[4][](5);
        quadrants[0] = [3, 3, 4, 4];
        quadrants[1] = [1, 2, 2, 1];
        quadrants[2] = [1, 1, 2, 2];
        quadrants[3] = [2, 3, 2, 3];
        quadrants[4] = [2, 3, 2, 3];

        string[] memory tokenURIs = new string[](5);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";
        tokenURIs[4] = "https://example.com/token/5";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[4]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);

        // call the pick function to get a random tokenid
        uint256 requestId = GemFactory(gemfactory).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(requestId);

        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactory).getRandomRequest(0);
        assert(GemFactory(gemfactory).ownerOf(randomRequest.chosenTokenId) == user1);
        vm.stopPrank();
    }

    function teststartMiningGEMRevertsIfNoMiningTryLeft() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](5);
        colors[0] = [0, 1];
        colors[1] = [1, 1];
        colors[2] = [1, 1];
        colors[3] = [1, 1];
        colors[4] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](5);
        rarities[0] = GemFactoryStorage.Rarity.UNIQUE;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;
        rarities[2] = GemFactoryStorage.Rarity.COMMON;
        rarities[3] = GemFactoryStorage.Rarity.RARE;
        rarities[4] = GemFactoryStorage.Rarity.RARE;

        uint8[4][] memory quadrants = new uint8[4][](5);
        quadrants[0] = [3, 3, 4, 4];
        quadrants[1] = [1, 2, 2, 1];
        quadrants[2] = [1, 1, 2, 2];
        quadrants[3] = [2, 3, 2, 3];
        quadrants[4] = [2, 3, 2, 3];

        string[] memory tokenURIs = new string[](5);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";
        tokenURIs[4] = "https://example.com/token/5";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[4]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);

        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);
        uint256 requestId = GemFactory(gemfactory).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(requestId);

        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactory).getRandomRequest(0);
        assert(GemFactory(gemfactory).ownerOf(randomRequest.chosenTokenId) == user1);
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);
        vm.expectRevert("no mining power left for that GEM");
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);
        
        vm.stopPrank();

    }

    function testStartAndPickMiningTwice() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](5);
        colors[0] = [0, 1];
        colors[1] = [1, 1];
        colors[2] = [1, 1];
        colors[3] = [1, 1];
        colors[4] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](5);
        rarities[0] = GemFactoryStorage.Rarity.EPIC;
        rarities[1] = GemFactoryStorage.Rarity.COMMON;
        rarities[2] = GemFactoryStorage.Rarity.COMMON;
        rarities[3] = GemFactoryStorage.Rarity.RARE;
        rarities[4] = GemFactoryStorage.Rarity.RARE;

        uint8[4][] memory quadrants = new uint8[4][](5);
        quadrants[0] = [5, 5, 4, 4];
        quadrants[1] = [1, 2, 2, 1];
        quadrants[2] = [1, 1, 2, 2];
        quadrants[3] = [2, 3, 2, 3];
        quadrants[4] = [2, 3, 2, 3];

        string[] memory tokenURIs = new string[](5);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";
        tokenURIs[2] = "https://example.com/token/3";
        tokenURIs[3] = "https://example.com/token/4";
        tokenURIs[4] = "https://example.com/token/5";

        // Call createPreminedGEMPool function from the Treasury contract
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[2]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[3]) == address(treasury));
        assert(GemFactory(gemfactory).ownerOf(newGemIds[4]) == address(treasury));

        // Transfer the GEM to user1
        GemFactory(gemfactory).adminTransferGEM(user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);

        // move on until the cooldown elapses
        vm.warp(block.timestamp + EpicGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + EpicGemsMiningPeriod + 1);
        uint256 firstRequestId = GemFactory(gemfactory).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(firstRequestId);

        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactory).getRandomRequest(0);
        assert(GemFactory(gemfactory).ownerOf(randomRequest.chosenTokenId) == user1);

        // move on until the cooldown elapses
        vm.warp(block.timestamp + EpicGemsCooldownPeriod + 1);

        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);

        // move on until the mining period elapses
        vm.warp(block.timestamp + EpicGemsMiningPeriod + 1);
        uint256 secondRequestId = GemFactory(gemfactory).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(secondRequestId);
        GemFactoryStorage.RequestStatus memory secondRandomRequest = GemFactory(gemfactory).getRandomRequest(1);
        assert(GemFactory(gemfactory).ownerOf(secondRandomRequest.chosenTokenId) == user1);
        vm.stopPrank();

    }

}
