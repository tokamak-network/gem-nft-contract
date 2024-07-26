// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./BaseTest.sol";

contract MarketPlaceTest is BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testPutGemForSale() public {
        vm.startPrank(owner);

        // Define GEM properties
        string memory color = "Red";
        uint256 value = 1000 * 10 ** 27;
        bytes1 quadrants = 0x34;
        string memory backgroundColor = "Black";
        uint256 miningPeriod = 3600; // 1 hour
        uint256 cooldownPeriod = 3600 * 72; // 72 hours
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            color,
            value,
            quadrants,
            backgroundColor,
            miningPeriod,
            cooldownPeriod,
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

        GemFactory(gemfactory).approve(address(marketplace), newGemId);
        MarketPlace(marketplace).putGemForSale(newGemId, gemPrice);

        vm.stopPrank();
    }

    function testPutGemlistForSale() public {
        vm.startPrank(owner);

        // Define GEM properties
        string[] memory colors = new string[](2);
        colors[0] = "Red";
        colors[1] = "Blue";

        uint256[] memory values = new uint256[](2);
        values[0] = 10 * 10 ** 27; // 10 WSTON
        values[1] = 150 * 10 ** 27; // 150 WSTON

        bytes1[] memory quadrants = new bytes1[](2);
        quadrants[0] = 0x0B;
        quadrants[1] = 0x22;

        string[] memory backgroundColors = new string[](2);
        backgroundColors[0] = "Black";
        backgroundColors[1] = "White";

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
            colors,
            values,
            quadrants,
            backgroundColors,
            miningPeriods,
            cooldownPeriods,
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

        vm.stopPrank();
    }

    function testBuyGem() public {
        vm.startPrank(owner);

        // Define GEM properties
        string memory color = "Red";
        uint256 value = 100 * 10 ** 27;
        bytes1 quadrants = 0x34;
        string memory backgroundColor = "Black";
        uint256 miningPeriod = 3600; // 1 hour
        uint256 cooldownPeriod = 3600 * 72; // 72 hours
        string memory tokenURI = "https://example.com/token/1";

        // Call createGEM function from the Treasury contract
        uint256 newGemId = Treasury(treasury).createPreminedGEM(
            color,
            value,
            quadrants,
            backgroundColor,
            miningPeriod,
            cooldownPeriod,
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
        MarketPlace(marketplace).buyGem(newGemId, false);
        assert(IERC20(wston).balanceOf(user1) == 1200 * 10 ** 27); // User1 should receive the WSTON (we now has 1000 + 200 WSTON)
        assert(GemFactory(gemfactory).ownerOf(newGemId) == user2); // GEM was correctly trransferred
        vm.stopPrank();
    }
}
