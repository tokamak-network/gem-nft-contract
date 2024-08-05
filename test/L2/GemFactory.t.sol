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

        // Verify the new gem is created and owned by user1
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

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
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[4] memory quadrants = [1, 2, 1, 1];
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
        uint256 oneWeek = 7 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + oneWeek + 1);

        vm.stopPrank();

        // Expect the transaction to succeed
        vm.prank(user1);
        bool result = GemFactory(gemfactory).startMiningGEM{value: commonMiningFees}(newGemId);
        assert(result == true);
    }


    function testStartMiningGEMRevertsIfCooldownNotElapsed() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[4] memory quadrants = [1, 2, 1, 1];
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

        vm.stopPrank();

        vm.prank(user1);

        // Expect the transaction to revert with the error message "Gem cooldown period has not elapsed"
        vm.expectRevert("Gem cooldown period has not elapsed");
        GemFactory(gemfactory).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    function testStartMiningGEMRevertsIfGemLocked() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[4] memory quadrants = [1, 2, 1, 1];
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
        uint256 oneWeek = 7 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + oneWeek + 1);

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

    function testStartMiningGEMRevertsIfUserAlreadyMining() public {
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

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 oneWeek = 7 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + oneWeek + 1);

        vm.stopPrank();

        vm.prank(user1);

        // Ensure the user is mining the first GEM
        GemFactory(gemfactory).startMiningGEM(newGemIds[0]);

        // Expect the transaction to revert with the error message "user is already mining"
        vm.expectRevert("user is already mining");
        GemFactory(gemfactory).startMiningGEM(newGemIds[1]);

        vm.stopPrank();
    }

    function testStartMiningGEMRevertsIfNotOwner() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[4] memory quadrants = [1, 2, 1, 1];
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
        uint256 oneWeek = 7 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + oneWeek + 1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        vm.stopPrank();

        vm.prank(user2);

        // Expect the transaction to revert with the error message "GEMIndexToOwner[_tokenId] == msg.sender"
        vm.expectRevert("not gem owner");
        GemFactory(gemfactory).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    function testStartMiningGEMRevertsIfNotEnoughFunds() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[4] memory quadrants = [1, 2, 1, 1];
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
        uint256 oneWeek = 7 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + oneWeek + 1);

        // Define the mining fees
        uint256 miningFees = commonMiningFees;

        vm.stopPrank();

        vm.prank(user1);

        // Expect the transaction to revert with the error message "Not enough funds"
        vm.expectRevert("Not enough funds");
        GemFactory(gemfactory).startMiningGEM{value: miningFees - 1}(newGemId);

        vm.stopPrank();
    }

}
