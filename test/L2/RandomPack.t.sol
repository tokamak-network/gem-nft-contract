// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";

contract MarketPlaceTest is L2BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testGetRandomGem() public {

        // create a pool of premined gem
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

        // Verify GEM creation
        assert(newGemIds.length == 2);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == treasuryProxyAddress);
        assert(keccak256(abi.encodePacked(GemFactory(gemfactory).tokenURI(newGemIds[0]))) == keccak256(abi.encodePacked(tokenURIs[0])));
        assert(keccak256(abi.encodePacked(GemFactory(gemfactory).tokenURI(newGemIds[1]))) == keccak256(abi.encodePacked(tokenURIs[1])));

        vm.stopPrank();

        vm.startPrank(user1);

        MockTON(ton).approve(randomPack, randomPackFees);
        uint256 requestId = RandomPack(randomPack).requestRandomGem{value: randomBeaconFees}();

        drbCoordinatorMock.fulfillRandomness(requestId);

        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1 || GemFactory(gemfactory).ownerOf(newGemIds[1]) == user1);

        vm.stopPrank();
    }

    function testGetRandomGemIfNoGemAvailable() public {
        vm.startPrank(user1);

        MockTON(ton).approve(randomPack, randomPackFees);

        uint256 requestId = RandomPack(randomPack).requestRandomGem{value: randomBeaconFees}();

        // Expect the CommonGemMinted event to be emitted
        vm.expectEmit(false, false, false, true);
        emit CommonGemMinted();
        drbCoordinatorMock.fulfillRandomness(requestId);

        vm.stopPrank();
    }
}
