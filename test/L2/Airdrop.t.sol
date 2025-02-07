// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import { AirdropStorage } from "../../src/L2/AirdropStorage.sol";


contract AirdropTest is L2BaseTest {
        error ContractPaused();
    error ContractNotPaused();
    function setUp() public override {
        super.setUp();
    }

    /**     
    * @notice testing the behavior of assignGemForAirdrop function
    * Creating two gems (one RARE and one UNIQUE) => owned by the treasury and eligible for airdrop/randomPack/Mining
    * Assigning these gems to user1 => gems are locked and can only be be claimed by user1
    */
    function testAssignGemForAirdrop() public {
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        bool success = Airdrop(airdropProxyAddress).assignGemForAirdrop(newGemIds, user1);
        assertTrue(success, "Assigning tokens should succeed");
        
        uint256[] memory _tokenIds = Airdrop(airdropProxyAddress).getTokensEligible(user1);
        assert(newGemIds[0] == _tokenIds[0]);
        assert(newGemIds[1] == _tokenIds[1]);

        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(_tokenIds[0]) == true);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(_tokenIds[1]) == true);

        vm.stopPrank();
    }

    /**     
    * @notice testing the behavior of assignGemForAirdrop function if called by a random user
    */
    function testAssignGemForAirdropShouldRevertIfNotOwnerOrAdmin() public {
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );
        vm.stopPrank();

        //we assume user1 tries to assign both gems for himself
        vm.startPrank(user1);
        vm.expectRevert("not Owner or Admin");
        Airdrop(airdropProxyAddress).assignGemForAirdrop(newGemIds, user1);
        vm.stopPrank();
    }

    /**     
    * @notice testing the behavior of claimAirdrop function
    * Creating two gems (one RARE and one UNIQUE) => owned by the treasury and eligible for airdrop/randomPack/Mining
    * Assigning these gems to user1 => gems are locked and can only be be claimed by user1
    * call claimAirdrop function and assert gems are sent to user1
    */
    function testClaimAirdrop() public {
        testAssignGemForAirdrop();

        assert(GemFactory(gemfactoryProxyAddress).ownerOf(0) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(1) == treasuryProxyAddress);

        vm.startPrank(user1);
        Airdrop(airdropProxyAddress).claimAirdrop();
        vm.stopPrank();
        
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(0) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(1) == user1);
    }

    /**
     * @notice assert that the function reverts if a user tries to call claimAirdrop with no tokens assigned to his address
     */
    function testClaimAirdropShouldRevertIfNoGemAssigned() public {
        testAssignGemForAirdrop();

        // user2 tries to call claimAidrop
        vm.startPrank(user2);
        vm.expectRevert(AirdropStorage.UserNotEligible.selector);
        Airdrop(airdropProxyAddress).claimAirdrop();
        vm.stopPrank();
    }

    /**
     * @notice assert that the function reverts if the contract is paused
     */
    function testClaimAirdropShouldRevertIfPaused() public {
        testAssignGemForAirdrop();

        vm.startPrank(owner);
        Airdrop(airdropProxyAddress).pause();
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(ContractPaused.selector));
        Airdrop(airdropProxyAddress).claimAirdrop();
        vm.stopPrank();
    }

    /**     
     * @notice testing the behavior of clearEligibleTokensList function
     * We first Assign tokens to user1
     * owner calls clearEligibleTokensList 
     * Ensuring the storage variables are reset
     */
    function testClearEligibleTokensList() public {
        testAssignGemForAirdrop();

        vm.startPrank(owner);
        Airdrop(airdropProxyAddress).clearEligibleTokensList();
        vm.stopPrank();

        // Assert that the user's eligible tokens are cleared
        uint256[] memory clearedTokens = airdrop.getTokensEligible(user1);
        assertEq(clearedTokens.length, 0, "User should have no eligible tokens after clearing");

        // Assert that the userClaimed mapping is reset
        bool userClaimedStatus = airdrop.getUserClaimed(user1);
        assertFalse(userClaimedStatus, "User claimed status should be reset");

        // Assert that the usersWithEligibleTokens array is cleared
        address[] memory usersWithTokens = airdrop.getUsersWithEligibleTokens();
        assertEq(usersWithTokens.length, 0, "No users should have eligible tokens after clearing");

        // Assert that the userHasEligibleTokens mapping is reset
        bool hasEligibleTokens = airdrop.hasEligibleTokens(user1);
        assertFalse(hasEligibleTokens, "User should not have eligible tokens after clearing");
    }


}