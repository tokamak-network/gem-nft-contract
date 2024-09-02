// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./L2BaseTest.sol";

contract MarketPlaceTest is L2BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testPutGemForSale() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
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

        uint256 gemPrice = 1500 * 10 ** 27;

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);
        assert(GemFactory(gemfactory).isTokenLocked(newGemId) == true);

        vm.stopPrank();
    }

    function testPutGemForSaleFromTreasury() public {
                vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        uint256 gemPrice = 1500 * 10 ** 27;

        Treasury(treasury).putGemForSale(newGemId, gemPrice);
        assert(GemFactory(gemfactory).isTokenLocked(newGemId) == true);
        vm.stopPrank();

    }

    function testPutGemForSaleFromTreasuryRevertsIfNotOwner() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        vm.stopPrank();
        vm.startPrank(user1);

        // Verify GEM minting
        assert(GemFactory(gemfactory).ownerOf(newGemId) == address(treasury));

        uint256 gemPrice = 1500 * 10 ** 27;
        vm.expectRevert("not Owner or Admin");
        Treasury(treasury).putGemForSale(newGemId, gemPrice);
        
        vm.stopPrank();

    }

    function testPutGemlistForSale() public {
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
        quadrants[1] = [4, 3, 4, 4];

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

        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactory).ownerOf(newGemIds[1]) == user1);

        GemFactory(gemfactory).approve(address(marketplace), newGemIds[0]);
        MarketPlace(marketplace).putGemListForSale(newGemIds, prices);
        assert(GemFactory(gemfactory).isTokenLocked(newGemIds[0]) == true);
        assert(GemFactory(gemfactory).isTokenLocked(newGemIds[1]) == true);

        vm.stopPrank();
    }

    function testPutGemlistForSaleFromTreasury() public {
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
        quadrants[1] = [4, 3, 4, 4];

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


        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 

        Treasury(treasury).putGemListForSale(newGemIds, prices);
        assert(GemFactory(gemfactory).isTokenLocked(newGemIds[0]) == true);
        assert(GemFactory(gemfactory).isTokenLocked(newGemIds[1]) == true);

        vm.stopPrank();
    }

    function testBuyGem() public {
        vm.startPrank(owner);
        
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
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

        uint256 gemPrice = 200 * 10 ** 27;

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user1);

        GemFactory(gemfactory).approve(address(marketplace), newGemId);
        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);

        vm.stopPrank();

        vm.startPrank(user2);
        IERC20(wston).approve(address(marketplace), type(uint256).max);
        IERC20(ton).approve(address(marketplace), type(uint256).max);

        uint256 balanceBefore = IERC20(wston).balanceOf(user1);

        MarketPlace(marketplace).buyGem(newGemId, false);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);

        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
        
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user2); // GEM was correctly trransferred
        vm.stopPrank();
    }

    function testBuyGemFromTreasury() public {
        vm.startPrank(owner);
        
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
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

        uint256 gemPrice = 200 * 10 ** 27;
        GemFactory(gemfactory).approve(address(marketplace), newGemId);
        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);

        vm.stopPrank();

        vm.startPrank(owner);
        Treasury(treasury).wstonApproveMarketPlace();
        Treasury(treasury).tonApproveMarketPlace();

        uint256 balanceBefore = IERC20(wston).balanceOf(user1);

        Treasury(treasury).buyGem(newGemId, false);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);

        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
        
        assert(GemFactory(gemfactory).ownerOf(newGemId) == treasury); // GEM was correctly trransferred to the treasury
        vm.stopPrank();
    }

    function testBuyGemFromTreasuryRevertsIfNotOwner() public {
        vm.startPrank(owner);
        
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
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

        uint256 gemPrice = 200 * 10 ** 27;
        GemFactory(gemfactory).approve(address(marketplace), newGemId);
        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);

        vm.stopPrank();

        vm.startPrank(owner);
        Treasury(treasury).wstonApproveMarketPlace();
        Treasury(treasury).tonApproveMarketPlace();

        vm.stopPrank();
        vm.startPrank(user2);
        
        vm.expectRevert("not Owner or Admin");
        Treasury(treasury).buyGem(newGemId, false);

        vm.stopPrank();
    }

    function testBuyCommonGem() public {
        vm.startPrank(user1);

        uint256 wstonTreasuryBalanceBefore = IERC20(wston).balanceOf(treasury);

        IERC20(wston).approve(marketplace, CommonGemsValue);
        uint256 newTokenId = MarketPlace(marketplace).buyCommonGem();

        uint256 wstonTreasuryBalanceAfter = IERC20(wston).balanceOf(treasury);

        assert(GemFactory(gemfactory).ownerOf(newTokenId) == user1);
        assert(wstonTreasuryBalanceAfter == wstonTreasuryBalanceBefore + CommonGemsValue);

        vm.stopPrank;
    }
}
