// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import "../../src/L2/MarketPlaceStorage.sol";
import "../../src/L2/MarketPlaceThanos.sol";
import "../../src/L2/TreasuryThanos.sol";

contract MarketPlaceThanosTest is L2BaseTest {

    MarketPlaceThanos marketplacethanos;
    TreasuryThanos treasurythanos;

    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        marketplacethanos = new MarketPlaceThanos();
        marketplacethanos.initialize(
            treasuryProxyAddress,
            gemfactoryProxyAddress,
            tonFeesRate,
            wston
        );
        treasurythanos = new TreasuryThanos();
        treasuryProxy.upgradeTo(address(treasurythanos));
        GemFactory(gemfactoryProxyAddress).setMarketPlaceAddress(address(marketplacethanos));
        Treasury(treasuryProxyAddress).setMarketPlace(address(marketplacethanos));  
        vm.deal(treasuryProxyAddress, 1000000 ether);
        vm.stopPrank();
    }

    // ----------------------------------- INITIALIZERS --------------------------------------

    /**
     * @notice testing the behavior of initialize function if called for the second time
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        // should revert
        vm.expectRevert(MarketPlaceStorage.AlreadyInitialized.selector);
        marketplacethanos.initialize(
            treasuryProxyAddress,
            gemfactoryProxyAddress,
            tonFeesRate,
            wston
        );
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setDiscountRate function
     */
    function testsetDiscountRate() public {
        uint256 newDiscountRate = 5;

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit MarketPlaceStorage.SetDiscountRate(newDiscountRate);
        marketplacethanos.setDiscountRate(newDiscountRate);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setDiscountRate function if called by a random user
     */
    function testsetDiscountRateShouldRevertIfNotOwner() public {
        uint256 newDiscountRate = 5;
        // not owner
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        marketplacethanos.setDiscountRate(newDiscountRate);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setStakingIndex function
     */
    function testsetStakingIndex() public {
        uint256 stakingIndex = 1063100206614753047688069608;
        
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit MarketPlaceStorage.SetStakingIndex(stakingIndex);
        marketplacethanos.setStakingIndex(stakingIndex);

        assert(marketplacethanos.getStakingIndex() == stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setStakingIndex function if the value passed is wrong
     */
    function testsetStakingIndexShouldRevertIfWrongValue() public {
        // value not correct
        uint256 stakingIndex = 0;
        
        // authorized user
        vm.startPrank(owner);
        vm.expectRevert(MarketPlaceStorage.WrongStakingIndex.selector);
        marketplacethanos.setStakingIndex(stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of setStakingIndex function if called by a random user
     */
    function testsetStakingIndexShouldRevertIfNotOwner() public {
        // correct value
        uint256 stakingIndex = 1063100206614753047688069608;

        // unauthorized user
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        marketplacethanos.setStakingIndex(stakingIndex);
        vm.stopPrank();
    }

    // ----------------------------------- CORE FUNCTIONS --------------------------------------

    /**
     * @notice testing the behavior of putGemForSale function
     */
    function testPutGemForSale() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);

        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);

        vm.stopPrank();

        vm.startPrank(user1);

        uint256 gemPrice = 1500 * 10 ** 27;

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);

        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);

        vm.expectEmit(true, true, true, true);
        emit MarketPlaceStorage.GemForSale(newGemId, user1, gemPrice);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemId) == true);

        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemForSale function from the treasury 
    */
    function testPutGemForSaleFromTreasury() public {
                vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);

        uint256 gemPrice = 1500 * 10 ** 27;
        Treasury(treasuryProxyAddress).approveGem(address(marketplacethanos), newGemId);
        Treasury(treasuryProxyAddress).putGemForSale(newGemId, gemPrice);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemId) == true);
        vm.stopPrank();

    }

    /**
    * @notice testing the behavior of putGemForSale function from the treasury if the caller is not the owner
    */
    function testPutGemForSaleFromTreasuryRevertsIfNotOwner() public {
        vm.startPrank(owner);

        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        Treasury(treasuryProxyAddress).approveGem(address(marketplacethanos), newGemId);

        vm.stopPrank();
        vm.startPrank(user1);

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);

        uint256 gemPrice = 1500 * 10 ** 27;
        vm.expectRevert("not Owner or Admin");
        Treasury(treasuryProxyAddress).putGemForSale(newGemId, gemPrice);
        
        vm.stopPrank();

    }

    /**
    * @notice testing the behavior of putGemForSale function if the Gem is locked
    * @dev we created a new Gem, transferred it to user1 and put it for sale. Then user1 tries to put it for sale a second time
    * @dev the function putGemForSale reverts with the error GemIsAlreadyForSaleOrIsMining
    */
    function testputGemForSaleShouldRevertIfGemIsLocked() public {
        testPutGemForSale();
        uint256 price = 1500 * 10 ** 27;
        vm.startPrank(user1);
        vm.expectRevert(MarketPlaceStorage.GemIsAlreadyForSaleOrIsMining.selector);
        marketplacethanos.putGemForSale(0, price);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemForSale function if the prce is equal to zero
    * @dev we created a new Gem, transferred it to user1 and put it for sale with a price = 0
    * @dev the function putGemForSale reverts with the error WrongPrice
    */
    function testputGemForSaleShouldRevertIfPriceEqualToZero() public {
        vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";
        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 gemPrice = 0;
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        vm.expectRevert(MarketPlaceStorage.WrongPrice.selector);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemListForSale function 
    */
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

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

        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 

        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == user1);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == user1);

        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemIds[1]);
        marketplacethanos.putGemListForSale(newGemIds, prices);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemIds[0]) == true);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemIds[1]) == true);

        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemListForSale function if called from the treasury
    */
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[0]) == treasuryProxyAddress);
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemIds[1]) == treasuryProxyAddress);


        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 

        Treasury(treasuryProxyAddress).approveGem(address(marketplacethanos), newGemIds[0]);
        Treasury(treasuryProxyAddress).approveGem(address(marketplacethanos), newGemIds[1]);

        Treasury(treasuryProxyAddress).putGemListForSale(newGemIds, prices);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemIds[0]) == true);
        assert(GemFactory(gemfactoryProxyAddress).isTokenLocked(newGemIds[1]) == true);

        vm.stopPrank();
    }
    
    /**
    * @notice testing the behavior of putGemListForSale function if the array of tokens is empty
    */
    function testPutGemListForSaleShouldRevertIfTokenListEmpty() public {
        vm.startPrank(user1);
        // empty array
        uint256[] memory tokenIds = new uint256[](0);
        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 
        vm.expectRevert(MarketPlaceStorage.NoTokens.selector);
        marketplacethanos.putGemListForSale(tokenIds, prices);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemListForSale function if the length of tokenIds is different from the length of prices
    */
    function testPutGemListForSaleShouldRevertIfDifferentLengths() public {
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );

        vm.startPrank(treasuryProxyAddress);

        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);

        vm.stopPrank();

        vm.startPrank(user1);
        // setting a wrong array of prices
        uint256[] memory prices = new uint256[](3);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; // 300 WSTON
        prices[2] = 400 * 10 ** 27; // 400 WSTON
        vm.expectRevert(MarketPlaceStorage.WrongLength.selector);
        marketplacethanos.putGemListForSale(newGemIds, prices);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of putGemListForSale function if the the user did not approve the transfer
    */
    function testPutGemListForSaleShouldRevertIfGemsNotApproved() public {
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
        uint256[] memory newGemIds = Treasury(treasuryProxyAddress).createPreminedGEMPool(
            rarities,
            colors,
            quadrants,
            tokenURIs
        );
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[0]);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemIds[1]);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256[] memory prices = new uint256[](2);
        prices[0] = 20 * 10 ** 27; // 10 WSTON
        prices[1] = 300 * 10 ** 27; 

        vm.expectRevert(MarketPlaceStorage.GemNotApproved.selector);
        marketplacethanos.putGemListForSale(newGemIds, prices);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of removeGemForSale function
    */
    function testRemoveGemForSale() public {
        // user1 puts tokenId=0 for sale
        testPutGemForSale();
        vm.startPrank(user1);
        vm.expectEmit(true,true,true,true);
        emit MarketPlaceStorage.GemRemovedFromSale(user1, 0);
        marketplacethanos.removeGemForSale(0);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of removeGemForSale function if the Gem is not listed
    */
    function testRemoveGemForSaleShouldRevertIfGemIsNotListed() public {
        vm.startPrank(user1);
        vm.expectRevert(MarketPlaceStorage.GemIsNotForSale.selector);
        marketplacethanos.removeGemForSale(0);
        vm.stopPrank();
    }

    function testRemoveGemForSaleShouldRevertIfPaused() public {
        // user1 puts tokenId=0 for sale
        testPutGemForSale();
        
        vm.startPrank(owner);
        marketplacethanos.pause();
        assert(marketplacethanos.getPaused() == true);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(MarketPlaceStorage.Paused.selector);
        marketplacethanos.removeGemForSale(0);
        vm.stopPrank();
    }

    function testRemoveGemForSaleShouldRevertIfNotGemOwner() public {
        // user1 puts tokenId=0 for sale
        testPutGemForSale();
        // user2 tries to removeGemForSale
        vm.startPrank(user2);
        vm.expectRevert(MarketPlaceStorage.NotGemOwner.selector);
        marketplacethanos.removeGemForSale(0);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function 
    */
    function testBuyGem() public {
        vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";
        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 gemPrice = 200 * 10 ** 27;
        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        uint256 totalprice = _toWAD(gemPrice + ((gemPrice * tonFeesRate) / 10000));
        marketplacethanos.buyGem{value: totalprice}(newGemId, false);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
    
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user2); // GEM was correctly trransferred
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function if the price chosen is WSTON
    */
    function testBuyGemInWston() public {
        vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";
        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        // treasury transfers the gem to user1
        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        // user1 lists the gem for sale
        vm.startPrank(user1);
        uint256 gemPrice = 200 * 10 ** 27;
        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();
        
        // user2 buys the gem   
        vm.startPrank(user2);
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        IERC20(wston).approve(address(marketplacethanos), gemPrice);
        marketplacethanos.buyGem(newGemId, true);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
    
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user2); // GEM was correctly trransferred
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function from the treasury
    */
    function testBuyGemFromTreasury() public {
        vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";
        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        // Transfer the GEMs to user1
        vm.startPrank(treasuryProxyAddress);
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        // put gem for sale
        vm.startPrank(user1);
        uint256 gemPrice = 200 * 10 ** 27;
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();

        // buy from treasury
        vm.startPrank(owner);
        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        TreasuryThanos(treasuryProxyAddress).buyGem(newGemId, false);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);
        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress); // GEM was correctly trransferred to the treasury
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function from the treasury if the caller is not the owner
    */
    function testBuyGemFromTreasuryRevertsIfNotOwner() public {
        vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";
        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        vm.stopPrank();

        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 gemPrice = 200 * 10 ** 27;
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert("not Owner or Admin");
        TreasuryThanos(treasuryProxyAddress).buyGem(newGemId, false);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function if the staking index has been updated
    */
    function testBuyGemWithNewStakingIndex() public {
         
         vm.startPrank(owner);
        // Define GEM properties
        GemFactoryStorage.Rarity rarity = GemFactoryStorage.Rarity.COMMON;
        uint8[2] memory color = [0,0];
        uint8[4] memory quadrants = [1, 1, 1, 2];
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasuryProxyAddress).createPreminedGEM(
            rarity,
            color,
            quadrants,
            tokenURI
        );
        // Verify GEM minting
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == treasuryProxyAddress);
        marketplacethanos.setStakingIndex(1063100206614753047688069608);
        vm.stopPrank();

        // prank the treasury to transfer ownership of the GEM to user 1
        vm.startPrank(treasuryProxyAddress);
        // Transfer the GEMs to user1
        GemFactory(gemfactoryProxyAddress).transferFrom(treasuryProxyAddress, user1, newGemId);
        vm.stopPrank();

        vm.startPrank(user1);
        uint256 gemPrice = 200 * 10 ** 27;
        // Verify token existence before putting it for sale
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user1);
        GemFactory(gemfactoryProxyAddress).approve(address(marketplacethanos), newGemId);
        marketplacethanos.putGemForSale(newGemId, gemPrice);
        vm.stopPrank();

        vm.startPrank(user2);
        IERC20(wston).approve(marketplaceProxyAddress, type(uint256).max);
        IERC20(ton).approve(marketplaceProxyAddress, type(uint256).max);

        uint256 balanceBefore = IERC20(wston).balanceOf(user1);
        uint256 wstonPrice = (gemPrice * 1063100206614753047688069608) / 10**27;
        uint256 totalprice = _toWAD(wstonPrice + ((wstonPrice * tonFeesRate) / 10000));
        marketplacethanos.buyGem{value: totalprice}(newGemId, false);
        uint256 balanceAfter = IERC20(wston).balanceOf(user1);

        assert(balanceAfter == balanceBefore + gemPrice); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
        
        assert(GemFactory(gemfactoryProxyAddress).ownerOf(newGemId) == user2); // GEM was correctly transferred
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function if the GEM is not for sale
    */
    function testBuyGemShouldRevertIfTheGemIsNotForSale() public {
        vm.startPrank(user2);
        vm.expectRevert(MarketPlaceStorage.GemIsNotForSale.selector);
        marketplacethanos.buyGem(0, false);
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of buyGem function if the buyer is the seller
    */
    function testBuyGemShouldRevertIfTheBuyerIsTheSeller() public {
        testPutGemForSale();
        vm.startPrank(user1);

        // ABI encode the expected error with its parameter
        bytes memory expectedError = abi.encodeWithSignature(
            "BuyerIsSeller(string)",
            "Use RemoveGemFromList instead"
        );

        vm.expectRevert(expectedError);
        marketplacethanos.buyGem(0, false);
        vm.stopPrank();
    }

    // ----------------------------------- PAUSE/UNPAUSE --------------------------------------

    /**
     * @notice testing the behavior of pause function
     */
    function testPause() public {
        vm.startPrank(owner);
        marketplacethanos.pause();
        assert( marketplacethanos.getPaused() == true);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        marketplacethanos.pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testPauseShouldRevertIfPaused() public {
        testPause();
        vm.startPrank(owner);
        vm.expectRevert(MarketPlaceStorage.Paused.selector);
        marketplacethanos.pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
        marketplacethanos.unpause();
        assert( marketplacethanos.getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        marketplacethanos.unpause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testUnpauseShouldRevertIfunpaused() public {
        vm.startPrank(owner);
        vm.expectRevert(MarketPlaceStorage.NotPaused.selector);
        marketplacethanos.unpause();
        vm.stopPrank();
    }


    // ----------------------------------- UTILS --------------------------------------

    /**
     * @dev Converts a value from RAY (27 decimals) to WAD (18 decimals).
     * @param v The value to convert.
     * @return The converted value in WAD.
     */
    function _toWAD(uint256 v) internal pure returns (uint256) {
        return v / 10 ** 9;
    }
}
