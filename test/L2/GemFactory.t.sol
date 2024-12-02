// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import "../../src/libraries/ForgeLibrary.sol";

contract GemFactoryTest is L2BaseTest {
    error ContractPaused();
    error ContractNotPaused();
    error UnauthorizedCaller(address caller);

    function setUp() public override {
        super.setUp();
    }

    /**
     * @notice function defining a standard COMMON GEM
     */
    function defineDefaultGem()
        public
        pure
        returns (
            GemFactoryStorage.Rarity rarity,
            uint8[2] memory color,
            uint8[4] memory quadrants,
            string memory tokenURI
        )
    {
        // Define GEM properties
        rarity = GemFactoryStorage.Rarity.COMMON;
        color = [0, 0];
        quadrants = [1, 2, 1, 1];
        tokenURI = "https://example.com/token/1";
    }

    /**
     * @notice testing of the creation of a single GEM (should be done only from the treasury contract)
     */
    function testCreateGEM() public {
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // Verify GEM creation
        assert(newGemId == 0);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        assert(
            keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemId)))
                == keccak256(abi.encodePacked(tokenURI))
        );

        vm.stopPrank();
    }

    /**
     * @notice testing of the transferFrom function
     * @dev we assert that storage variables are approrpiately updated
     */
    function testTransferFrom() public {
        // creating a single GEM
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        //transferring the GEM from the treasury to user1
        vm.startPrank(treasuryProxyAddress);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        // checking the GEM was sent appropriately
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // ensuring the cooldown period was reset
        assert(GemFactory(gemfactoryProxyAddress).getGem(newGemId).gemCooldownDueDate == block.timestamp);

        // ensuring the tokenCount was updated accordingly
        assert(GemFactory(gemfactoryProxyAddress).getOwnershipTokenCount(treasuryProxyAddress) == 0);
        assert(GemFactory(gemfactoryProxyAddress).getOwnershipTokenCount(user1) == 1);
        vm.stopPrank();
    }

    /**
     * @notice testing of the behavior of transferFrom function if the gem is locked
     */
    function testTransferFromShouldRevertIftokenLocked() public {
        // creating a single GEM
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // listing the gem into the marketplace
        uint256 gemPrice = 1500 * 10 ** 27;
        Treasury(treasuryProxyAddress).approveGem(marketplaceProxyAddress, newGemId);
        Treasury(treasuryProxyAddress).putGemForSale(newGemId, gemPrice);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemId) == true);
        vm.stopPrank();

        // trying to transfer the gem => should revert
        vm.startPrank(treasuryProxyAddress);
        vm.expectRevert(GemFactoryStorage.GemIsLocked.selector);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
    }

    /**
     * @notice testing of the safeTransferFrom function
     */
    function testSafeTransferFrom() public {
        // creating a single GEM
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        vm.startPrank(treasuryProxyAddress);
        GemFactory(gemfactoryProxyAddress).safeTransferFrom(treasuryProxyAddress, user1, newGemId);
        // checking the GEM was sent appropriately
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // ensuring the cooldown period was reset
        assert(GemFactory(gemfactoryProxyAddress).getGem(newGemId).gemCooldownDueDate == block.timestamp);

        // ensuring the tokenCount was updated accordingly
        assert(GemFactory(gemfactoryProxyAddress).getOwnershipTokenCount(treasuryProxyAddress) == 0);
        assert(GemFactory(gemfactoryProxyAddress).getOwnershipTokenCount(user1) == 1);
        vm.stopPrank();
    }

    /**
     * @notice testing of the safeTransferFrom function's behavior if the recipient does not implement onERC721Receive function
     * to avoid tokens being locked inside of contracts
     * @dev we create a GEM for the treasury and send try to transfer the GEM to the airdrop contract which intendly does not implement onERC721Receive
     */
    function testSafeTransferFromShouldRevertIfRecipientNotAppropriate() public {
        // creating a single GEM
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        vm.startPrank(treasuryProxyAddress);
        // ensure the transfer fails due to the fact airdrop contract does not implement onERC721Receive function
        vm.expectRevert();
        GemFactory(gemfactoryProxyAddress).safeTransferFrom(treasuryProxyAddress, airdropProxyAddress, newGemId);

        vm.stopPrank();
    }

    /**
     * @notice testing the access restrictions of createGem function from GemFactory
     */
    function testCreateGEMShouldRevertIfNotFromTreasury() public {
        vm.startPrank(owner);

        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, owner));
        GemFactory(gemfactoryProxyAddress).createGEM(rarity, color, quadrants, tokenURI);

        vm.stopPrank();
    }

    /**
     * @notice testing the access restrictions of createPreminedGem function from the Treasury
     */
    function testCreatePreminedGEMShouldRevertIfNotFromOwner() public {
        // trying to create a GEM using user1's wallet
        vm.startPrank(user1);

        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        vm.expectRevert("caller is neither owner nor randomPack contract");
        Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        vm.stopPrank();
    }

    /**
     * @notice testing of the creation of multiple GEMs (should be done only from the treasury contract)
     */
    function testCreatePreminedGEMPool() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM creation
        assert(newGemIds.length == 2);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(
            keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemIds[0])))
                == keccak256(abi.encodePacked(tokenURIs[0]))
        );
        assert(
            keccak256(abi.encodePacked(GemFactory(gemfactoryProxyAddress).tokenURI(newGemIds[1])))
                == keccak256(abi.encodePacked(tokenURIs[1]))
        );

        vm.stopPrank();
    }

    /**
     * @notice testing the access restrictions of createPreminedGEMPool function from the Treasury
     */
    function testCreatePreminedGEMPoolShouldRevertIfNotFromOwner() public {
        // trying to create a GEM using user1's wallet
        vm.startPrank(user1);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.RARE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;

        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [2, 3, 3, 2];
        quadrants[1] = [4, 3, 4, 3];

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        vm.expectRevert("caller is neither owner nor randomPack contract");
        // Call createPreminedGEMPool function from the Treasury contract
        Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);
        vm.stopPrank();
    }

    /**
     * @notice testing the access restrictions of createGEMPool function from GemFactory
     */
    function testCreateGEMPoolShouldRevertIfNotFromTreasury() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2][] memory colors = new uint8[2][](2);
        colors[0] = [0, 0];
        colors[1] = [1, 1];

        GemFactoryStorage.Rarity[] memory rarities = new GemFactoryStorage.Rarity[](2);
        rarities[0] = GemFactoryStorage.Rarity.RARE;
        rarities[1] = GemFactoryStorage.Rarity.UNIQUE;

        uint8[4][] memory quadrants = new uint8[4][](2);
        quadrants[0] = [2, 3, 3, 2];
        quadrants[1] = [4, 3, 4, 3];

        string[] memory tokenURIs = new string[](2);
        tokenURIs[0] = "https://example.com/token/1";
        tokenURIs[1] = "https://example.com/token/2";

        vm.expectRevert(abi.encodeWithSelector(UnauthorizedCaller.selector, owner));
        GemFactory(gemfactoryProxyAddress).createGEMPool(rarities, colors, quadrants, tokenURIs);

        vm.stopPrank();
    }

    /**
     * @notice testing the melt function from the GemFactory
     */
    function testMeltGEM() public {
        vm.startPrank(owner);

        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);

        // Verify GEM transfer
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);

        vm.stopPrank();

        // Start prank as user1 to melt the GEM
        vm.startPrank(user1);
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        // Call meltGEM function
        GemFactory(gemfactoryProxyAddress).meltGEM(newGemId);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        uint256 gemValue = GemFactory(gemfactoryProxyAddress).getCommonGemsValue();
        // Verify GEM melting
        assert(balanceAfter == balanceBefore + gemValue); // User1 should receive the WSTON (we now has 1000 + 10 WSWTON)

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of a user trying to melt a GEM he does not own
     */
    function testMeltGEMShouldRevertIfNotGemOwner() public {
        vm.startPrank(owner);

        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);

        // Verify GEM transfer
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);

        vm.stopPrank();

        // Start prank as user2 and try to melt the GEM
        vm.startPrank(user2);
        vm.expectRevert(GemFactoryStorage.NotGemOwner.selector);
        GemFactory(gemfactoryProxyAddress).meltGEM(newGemId);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the contract is paused
     */
    function testMeltGEMShouldRevertIfContractPaused() public {
        vm.startPrank(owner);
        // defining a default GEM
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        // Verify GEM transfer
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        vm.stopPrank();

        // we pause the contract
        vm.startPrank(owner);
        GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();

        // Start prank as user2 and try to melt the GEM
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ContractPaused.selector));

        GemFactory(gemfactoryProxyAddress).meltGEM(newGemId);
        vm.stopPrank();
    }

    /**
     * @notice testing the forgeTokens function from GemFactory
     */
    function testForgeGem() public {
        vm.startPrank(owner);

        // Define GEMs properties
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];

        uint8[2] memory color = [0, 1];
        uint256 newGemId =
            GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        // Verify the new gem properties
        GemFactoryStorage.Gem memory newGem = GemFactory(gemfactoryProxyAddress).getGem(newGemId);
        assert(newGem.rarity == GemFactoryStorage.Rarity.RARE);
        assert(newGem.color[0] == color[0] && newGem.color[1] == color[1]);
        assert(newGem.gemCooldownDueDate == block.timestamp + RareGemsCooldownPeriod);

        // Verify the new gem quadrants
        assert(newGem.quadrants[0] == 2);
        assert(newGem.quadrants[1] == 3);
        assert(newGem.quadrants[2] == 3);
        assert(newGem.quadrants[3] == 2);

        vm.stopPrank();
    }

    /**
     * @notice testing the forgeTokens function from GemFactory with 4 Gems (rarity = UNIQUE)
     */
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[2]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[3]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == user1);

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        tokenIds[2] = newGemIds[2];
        tokenIds[3] = newGemIds[3];

        uint8[2] memory color = [1, 3];

        uint256 newGemId =
            GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.UNIQUE, color);

        // Verify the new gem properties
        GemFactoryStorage.Gem memory newGem = GemFactory(gemfactoryProxyAddress).getGem(newGemId);
        assert(newGem.rarity == GemFactoryStorage.Rarity.EPIC);
        assert(newGem.color[0] == color[0] && newGem.color[1] == color[1]);
        assert(newGem.gemCooldownDueDate == block.timestamp + EpicGemsCooldownPeriod);

        // Verify the new gem quadrants
        assert(newGem.quadrants[0] == 4);
        assert(newGem.quadrants[1] == 4);
        assert(newGem.quadrants[2] == 4);
        assert(newGem.quadrants[3] == 5);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the contract is paused
     */
    function testForgeGemsShouldRevertIfPaused() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);
        vm.stopPrank();

        // pausing the contract
        vm.startPrank(owner);
        GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();

        // attempt to forge => should revert
        vm.startPrank(user1);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        uint8[2] memory color = [0, 1];

        vm.expectRevert("Pausable: paused");
        GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the function caller is not the Gems owner
     */
    function testForgeGemsShouldRevertIfNotGemOwner() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);
        vm.stopPrank();

        // attempt to forge => should revert
        vm.startPrank(user2);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        uint8[2] memory color = [0, 1];

        vm.expectRevert(ForgeLibrary.NotGemOwner.selector);
        GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the rarity of the tokens passed in argument are not the same
     */
    function testForgeGemShouldRevertIfRaritiesNotSame() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];

        uint8[2] memory color = [0, 1];

        // Expect the transaction to revert with the error message "wrong rarity Gems"
        vm.expectRevert(ForgeLibrary.WrongRarity.selector);
        GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the color passed in argument does not follow the forging rules
     */
    function testForgeGemShouldRevertIfColorNotCorrect() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];

        // Define an invalid color that cannot be obtained from the input tokens
        uint8[2] memory invalidColor = [2, 3];

        // Expect the transaction to revert with the error message "this color can't be obtained"
        vm.expectRevert(ForgeLibrary.NotValidColor.selector);
        GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, invalidColor);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the function if the number of Gems to be forged are not correct
     */
    function testForgeGemShouldRevertIfGemsNumberNotCorrect() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);
        // Verify GEM creation
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[2]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[3]);
        vm.stopPrank();

        vm.startPrank(user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == user1);
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = newGemIds[0];
        tokenIds[1] = newGemIds[1];
        tokenIds[2] = newGemIds[2];
        tokenIds[3] = newGemIds[3];
        uint8[2] memory color = [2, 3];
        // Expect the transaction to revert with the error message "wrong number of Gems to be forged"
        vm.expectRevert(ForgeLibrary.WrongNumberOfGemToBeForged.selector);
        GemFactoryForging(gemfactoryProxyAddress).forgeTokens(tokenIds, GemFactoryStorage.Rarity.COMMON, color);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the StartMiningGem function from the GemFactory
     */
    function testStartMiningGEM() public {
        vm.startPrank(owner);
        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        // Verify token existence before starting mining
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);
        bool result = GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemId);
        assert(result == true);
    }

    /**
     * @notice testing the behavior of the StartMiningGem function if the contract is paused
     */
    function testStartMiningGEMShouldRevertIfPaused() public {
        vm.startPrank(owner);
        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        // Verify token existence before starting mining
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);
        vm.stopPrank();

        //pausing the contract
        vm.startPrank(owner);
        GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();

        // Expect the transaction to succeed
        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemId);
    }

    /**
     * @notice testing the behavior of the StartMiningGem function if the cooldown period has not elapsed
     */
    function testStartMiningGEMShouldRevertIfCooldownNotElapsed() public {
        vm.startPrank(owner);
        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        // Verify token existence before starting mining
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // Expect the transaction to revert with the error message "Gem cooldown period has not elapsed"
        vm.expectRevert(abi.encodeWithSignature("CooldownPeriodNotElapsed()"));
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the StartMiningGem function if the Gem is locked
     */
    function testStartMiningGEMShouldRevertIfGemLocked() public {
        vm.startPrank(owner);
        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";
        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        // Verify token existence before starting mining
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);
        // putGemFor sale before calling startMining to ensure Gem is locked
        uint256 gemPrice = 1500 * 10 ** 27;
        GemFactory(gemfactoryProxyAddress).approve(marketplaceProxyAddress, newGemId);
        MarketPlace(marketplaceProxyAddress).putGemForSale(newGemId, gemPrice);
        vm.stopPrank();

        vm.startPrank(user1);
        // Expect the transaction to revert with the error message "Gem is listed for sale or already mining"
        vm.expectRevert(abi.encodeWithSignature("GemIsLocked()"));
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemId);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the StartMiningGem function if the caller is not the gem owner
     */
    function testStartMiningGEMShouldRevertIfNotOwner() public {
        vm.startPrank(owner);

        // Define GEM properties
        uint8[2] memory color = [0, 0];
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.RARE;
        uint8[4] memory quadrants = [3, 2, 3, 3];
        string memory tokenURI = "https://example.com/token/1";

        // Create a GEM and transfer it to user1
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user2); // Different user

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        uint256 twoWeeks = 14 * 24 * 60 * 60; // 7 days in seconds
        vm.warp(block.timestamp + twoWeeks + 1);

        // Verify token existence before starting mining
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);

        vm.stopPrank();

        vm.prank(user2);

        // Expect the transaction to revert with the error message "GEMIndexToOwner[_tokenId] == msg.sender"
        vm.expectRevert(abi.encodeWithSignature("NotGemOwner()"));
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemId);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the cancelMining function
     */
    function testCancelMining() public {
        testStartMiningGEM();

        // call cancelMining function
        vm.startPrank(user1);
        uint256[] memory tokens = GemFactory(gemfactoryProxyAddress).tokensOfOwner(user1);
        // ensure the token is locked
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(tokens[0]) == true);
        // call cancelMining function
        GemFactoryMining(gemfactoryProxyAddress).cancelMining(tokens[0]);
        // ensure the token is not locked
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(tokens[0]) == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the cancelMining function if the contract is paused
     */
    function testCancelMiningshouldRevertIfPaused() public {
        testStartMiningGEM();

        // pausing the contract
        vm.startPrank(owner);
        GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();
        // call cancelMining function
        vm.startPrank(user1);
        uint256[] memory tokens = GemFactory(gemfactoryProxyAddress).tokensOfOwner(user1);

        // call cancelMining function
        vm.expectRevert("Pausable: paused");
        GemFactoryMining(gemfactoryProxyAddress).cancelMining(tokens[0]);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the cancelMining function if caller is not the gem owner
     */
    function testCancelMiningshouldRevertIfNotGemOwner() public {
        testStartMiningGEM();

        // call cancelMining function
        vm.startPrank(user2);
        uint256[] memory tokens = GemFactory(gemfactoryProxyAddress).tokensOfOwner(user1);

        // call cancelMining function
        vm.expectRevert(GemFactoryStorage.NotGemOwner.selector);
        GemFactoryMining(gemfactoryProxyAddress).cancelMining(tokens[0]);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the pickRandomGem function
     */
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[4]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify the gem ownership after transferring it from the treasury
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);
        // move foreward after the mining period time
        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);
        // call pickMinedGEM
        GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);
        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactoryProxyAddress).getRandomRequest(0);

        // check that the random request has been taken into account
        assert(randomRequest.fulfilled == false);
        assert(randomRequest.requested == true);
        assert(randomRequest.requester == user1);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the pickRandomGem function if the contract is paused
     */
    function testPickMinedGemShouldRevertIfPaused() public {
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[4]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify the gem ownership after transferring it from the treasury
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);
        // move foreward after the mining period time
        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);

        vm.stopPrank();

        vm.startPrank(owner);
        GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();

        vm.startPrank(user1);
        // call pickMinedGEM
        vm.expectRevert("Pausable: paused");
        GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);

        vm.stopPrank();
    }

    function testSetTreasury() public {
        vm.startPrank(owner);
        address newTreasuryAddress = address(0x123);
        GemFactory(gemfactoryProxyAddress).setTreasury(newTreasuryAddress);

        vm.stopPrank();
    }
   function testPause() public {
        vm.startPrank(owner);
       GemFactory(gemfactoryProxyAddress).pause();
        assert( GemFactory(gemfactoryProxyAddress).getPaused() == true);
        vm.stopPrank();
    }
      /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
       GemFactory(gemfactoryProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
       GemFactory(gemfactoryProxyAddress).unpause();
        assert( GemFactory(gemfactoryProxyAddress).getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert();
       GemFactory(gemfactoryProxyAddress).unpause();
        vm.stopPrank();
    }


  

    /**
     * @notice testing the behavior of the DRBCoordinator
     */
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[4]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);

        // Simulate the passage of time to ensure the GEM's cooldown period has elapsed
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);

        // call the pick function to get a random tokenid
        uint256 requestId = GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);
        // we simulate the coordinator calling filfillRandomness from the DRBConsumerBase abstract
        drbCoordinatorMock.fulfillRandomness(requestId);

        // ensure that the request has been fulfilled
        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactoryProxyAddress).getRandomRequest(0);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(randomRequest.chosenTokenId) == user1);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of the startMining if gem has no mining try left
     */
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[4]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);

        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + UniqueGemsMiningPeriod + 1);
        uint256 requestId = GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(requestId);

        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactoryProxyAddress).getRandomRequest(0);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(randomRequest.chosenTokenId) == user1);

        // we try to recall startMiningGem a second time
        vm.warp(block.timestamp + UniqueGemsCooldownPeriod + 1);
        vm.expectRevert(abi.encodeWithSignature("NoMiningTryLeft()"));
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);

        vm.stopPrank();
    }

    function testMeltGem() public {
        vm.startPrank(owner);

        // Define GEM properties
        (GemFactoryStorage.Rarity rarity, uint8[2] memory color, uint8[4] memory quadrants, string memory tokenURI) =
            defineDefaultGem();

        // Create a GEM
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(rarity, color, quadrants, tokenURI);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer GEM to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        // Melt the GEM as user1
        vm.startPrank(user1);
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);

        // Call meltGEM function
        GemFactory(gemfactoryProxyAddress).meltGEM(newGemId);

        // Verify WSTON balance update
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        uint256 gemValue = GemFactory(gemfactoryProxyAddress).getCommonGemsValue();
        assert(balanceAfter == balanceBefore + gemValue);

        vm.stopPrank();
    }

    function testGetRareGemsValue() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getRareGemsValue();
        assertEq(value, 19000000000000000000000000000);
    }

    function testGetUniqueGemsValue() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getUniqueGemsValue();
        assertEq(value, 53000000000000000000000000000);
    }

    function testGetEpicGemsValue() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getEpicGemsValue();
        assertEq(value, 204000000000000000000000000000);
    }

    function testGetLegendaryGemsValue() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getLegendaryGemsValue();
        assertEq(value, 605000000000000000000000000000);
    }

    function testGetMythicGemsValue() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getMythicGemsValue();
        assertEq(value, 4000000000000000000000000000000);
    }

    function testGetRareMiningTry() public view {
        uint8 value = GemFactory(gemfactoryProxyAddress).getRareminingTry();
        assertEq(value, 2);
    }

    function testGetUniqueMiningTry() public view {
        uint8 value = GemFactory(gemfactoryProxyAddress).getUniqueminingTry();
        assertEq(value, 1);
    }

    function testGetEpicMiningTry() public view {
        uint8 value = GemFactory(gemfactoryProxyAddress).getEpicminingTry();
        assertEq(value, 10);
    }

    function testGetLegendaryMiningTry() public view {
        uint8 value = GemFactory(gemfactoryProxyAddress).getLegendaryminingTry();
        assertEq(value, 15);
    }

    function testGetMythicMiningTry() public view {
        uint8 value = GemFactory(gemfactoryProxyAddress).getMythicminingTry();
        assertEq(value, 20);
    }

    function testGetRareGemsMiningPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getRareGemsMiningPeriod();
        assertEq(value, 1209600);
    }

    function testGetUniqueGemsMiningPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getUniqueGemsMiningPeriod();
        assertEq(value, 1814400);
    }

    function testGetEpicGemsMiningPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getEpicGemsMiningPeriod();
        assertEq(value, 2419200);
    }

    function testGetLegendaryGemsMiningPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getLegendaryGemsMiningPeriod();
        assertEq(value, 3024000);
    }

    function testGetMythicGemsMiningPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getMythicGemsMiningPeriod();
        assertEq(value, 3628800);
    }

    function testGetRareGemsCooldownPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getRareGemsCooldownPeriod();
        assertEq(value, 1209600);
    }

    function testGetUniqueGemsCooldownPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getUniqueGemsCooldownPeriod();
        assertEq(value, 1814400);
    }

    function testGetEpicGemsCooldownPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getEpicGemsCooldownPeriod();
        assertEq(value, 2419200);
    }

    function testGetLegendaryGemsCooldownPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getLegendaryGemsCooldownPeriod();
        assertEq(value, 3024000);
    }

    function testGetMythicGemsCooldownPeriod() public view {
        uint32 value = GemFactory(gemfactoryProxyAddress).getMythicGemsCooldownPeriod();
        assertEq(value, 3628800);
    }

    function testGetRequestCount() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getRequestCount();
        assertEq(value, 0);
    }

    function testGetOwnershipTokenCount() public view {
        uint256 value = GemFactory(gemfactoryProxyAddress).getOwnershipTokenCount(address(this));
        assertEq(value, 0);
    }
    /**
     * @notice testing the behavior of the mining process twice
     */
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
        uint256[] memory newGemIds =
            Treasury(treasuryProxyAddress).createPreminedGEMPool(rarities, colors, quadrants, tokenURIs);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[2]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[3]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[4]) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);

        vm.stopPrank();

        vm.startPrank(user1);

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);

        // move on until the cooldown elapses
        vm.warp(block.timestamp + EpicGemsCooldownPeriod + 1);

        // Ensure the user is mining the first GEM
        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);

        vm.warp(block.timestamp + EpicGemsMiningPeriod + 1);
        uint256 firstRequestId = GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(firstRequestId);

        GemFactoryStorage.RequestStatus memory randomRequest = GemFactory(gemfactoryProxyAddress).getRandomRequest(0);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(randomRequest.chosenTokenId) == user1);

        // move on until the cooldown elapses
        vm.warp(block.timestamp + EpicGemsCooldownPeriod + 1);

        GemFactoryMining(gemfactoryProxyAddress).startMiningGEM(newGemIds[0]);

        // move on until the mining period elapses
        vm.warp(block.timestamp + EpicGemsMiningPeriod + 1);
        uint256 secondRequestId = GemFactoryMining(gemfactoryProxyAddress).pickMinedGEM{value: miningFees}(newGemIds[0]);
        drbCoordinatorMock.fulfillRandomness(secondRequestId);
        GemFactoryStorage.RequestStatus memory secondRandomRequest =
            GemFactory(gemfactoryProxyAddress).getRandomRequest(1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(secondRandomRequest.chosenTokenId) == user1);
        vm.stopPrank();
    }
}
