// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./L2BaseTest.sol";

contract AirdropTest is L2BaseTest {
    function setUp() public override {
        super.setUp();
    }

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
        uint256[] memory newGemIds = Treasury(treasury).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        Airdrop(airdrop).assignGemForAirdrop(newGemIds, user1);
        
        uint256[] memory _tokenIds = Airdrop(airdrop).getTokensEligible(user1);
        assert(newGemIds[0] == _tokenIds[0]);
        assert(newGemIds[1] == _tokenIds[1]);

        vm.stopPrank();
    }

    function testClaimAirdrop() public {
        testAssignGemForAirdrop();

        assert(GemFactory(gemfactory).ownerOf(0) == treasury);
        assert(GemFactory(gemfactory).ownerOf(1) == treasury);

        vm.startPrank(user1);
        Airdrop(airdrop).claimAirdrop();
        vm.stopPrank();
        
        assert(GemFactory(gemfactory).ownerOf(0) == user1);
        assert(GemFactory(gemfactory).ownerOf(1) == user1);
    }
}