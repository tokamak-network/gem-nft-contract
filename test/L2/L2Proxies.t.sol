// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./WstonSwapV2.t.sol";
import {MockWstonSwapPoolUpgraded} from "./mock/MockSwapPoolUpgraded.sol";
import {MockTreasuryUpgraded} from "./mock/MockTreasuryUpgraded.sol";
import {MockMarketPlaceUpgraded} from "./mock/MockMarketPlaceUpgraded.sol";
import {MockAirdropUpgraded} from "./mock/MockAirdropUpgraded.sol";
import {MockGemFactoryUpgraded} from "./mock/MockGemFactoryUpgraded.sol";
import {MockRandomPackUpgraded} from "./mock/MockRandomPackUpgraded.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract L2ProxyTest is WstonSwap {

    MockWstonSwapPoolUpgraded mockSwapPoolUpgraded; 
    MockTreasuryUpgraded mockTreasuryUpgraded;
    MockMarketPlaceUpgraded mockMarketPlaceUpgraded;
    MockAirdropUpgraded mockAirdropUpgraded;
    MockGemFactoryUpgraded mockGemFactoryUpgraded;
    MockRandomPackUpgraded mockRandomPackUpgraded;
    
    /**
     * @dev We created a MockSwapPoolUpgraded and added a function called resetFees() which can only be called by the owner
     */
    function testWstonSwapPoolProxyUpgrade() public {
        // we replay the scenario where a users swaps (staking index > 1)
        testSwapWithUpdatedStakingIndex();

        // we upgrade the swapper
        vm.startPrank(owner);
        mockSwapPoolUpgraded = new MockWstonSwapPoolUpgraded();
        wstonSwapPoolProxyV2.upgradeTo(address(mockSwapPoolUpgraded));


        // we ensure that old storage variables were kept 
        uint256 stakingIndex = WstonSwapPoolV2(wstonSwapPoolProxyV2Address).getStakingIndex();
        assert(stakingIndex != 0);
        
        // we ensure the new implementation is considered by calling incrementCounter();
        MockWstonSwapPoolUpgraded(wstonSwapPoolProxyV2Address).incrementCounter();
        uint256 counter = MockWstonSwapPoolUpgraded(wstonSwapPoolProxyV2Address).getCounter();
        assert(counter == 1);

        vm.stopPrank();
    }

    /**
     * @dev The test tries to upgrade the WstonSwapPool contract using user1 account (not the owner). We expect it to revert
     */
    function testWstonSwapPoolProxyUpgradeRevertsIfNotOwner() public {
        // we replay the scenario where LP deposit and user1 swaps
        testSwapWithUpdatedStakingIndex();
        
        // we try to upgrade the swapper using user1 account
        vm.startPrank(user1);
        mockSwapPoolUpgraded = new MockWstonSwapPoolUpgraded();
        
        // we expect the upgradeTo function to revert
        vm.expectRevert("AuthControl: Caller is not the owner");
        wstonSwapPoolProxyV2.upgradeTo(address(mockSwapPoolUpgraded));

        vm.stopPrank();
    }

    function testProxyInitializeRevertsIfCalledTwice() public {
        testWstonSwapPoolProxyUpgrade();

        vm.startPrank(owner);

        // we expect the initialize function to revert
        vm.expectRevert("already initialized");
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).initialize(
            ton,
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress
        );
        vm.stopPrank();
    }

    /**
     * @dev We created a MockTreasuryUpgraded and added a storage variable called counter and a function incrementCounter()
     */
    function testTreasuryProxy() public {
        vm.startPrank(owner);
        mockTreasuryUpgraded = new MockTreasuryUpgraded();
        treasuryProxy.upgradeTo(address(mockTreasuryUpgraded));


        // fetching storage from the upgraded contract
        address randomPackAddress = MockTreasuryUpgraded(treasuryProxyAddress).getRandomPackAddress();
        address gemFactoryAddress = MockTreasuryUpgraded(treasuryProxyAddress).getGemFactoryAddress();
        uint256 wstonBalance = MockTreasuryUpgraded(treasuryProxyAddress).getWSTONBalance();
        uint256 tonBalance = MockTreasuryUpgraded(treasuryProxyAddress).getTONBalance();

        // assert storage are kept after upgrading
        assert(randomPackAddress != address(0));
        assert(gemFactoryAddress != address(0));
        assert(wstonBalance != 0);
        assert(tonBalance != 0);

        // check that the new counter storage and incrementCounter functions are deployed
        MockTreasuryUpgraded(treasuryProxyAddress).incrementCounter();
        uint256 counter = MockTreasuryUpgraded(treasuryProxyAddress).getCounter();
        assert(counter == 1);

    }

        /**
     * @dev The test tries to upgrade the WstonSwapPool contract using user1 account (not the owner). We expect it to revert
     */
    function testTreasuryProxyUpgradeRevertsIfNotOwner() public {
   
        // we try to upgrade the swapper using user1 account
        vm.startPrank(user1);
        mockTreasuryUpgraded = new MockTreasuryUpgraded();
        
        // we expect the upgradeTo function to revert
        vm.expectRevert("AuthControl: Caller is not the owner");
        treasuryProxy.upgradeTo(address(mockTreasuryUpgraded));

        vm.stopPrank();
    }

    /**
     * @dev We created a MockMarketPlaceUpgraded and added a new function buyCommonGem that allow users to buy unlimited amount of common Gems.
     */
    function testMarketplaceProxy() public {

        vm.startPrank(owner);

        // set a new staking index
        MarketPlace(marketplaceProxyAddress).setStakingIndex(1063100206614753047688069608);
        assert(MarketPlace(marketplaceProxyAddress).getStakingIndex() != 0);

        // upgrade the contract
        mockMarketPlaceUpgraded = new MockMarketPlaceUpgraded();
        marketplaceProxy.upgradeTo(address(mockMarketPlaceUpgraded));

        // checking that storage variables are correctly accessible and were not reset
        assert(MockMarketPlaceUpgraded(marketplaceProxyAddress).getTonFeesRate() != 0);
        assert(MockMarketPlaceUpgraded(marketplaceProxyAddress).getStakingIndex() != 0);
        assert(MockMarketPlaceUpgraded(marketplaceProxyAddress).getGemFactoryAddress() != address(0));
        assert(MockMarketPlaceUpgraded(marketplaceProxyAddress).getTreasuryAddress() != address(0));

        // test that the new function is available
        IERC20(wston).approve(marketplaceProxyAddress, type(uint256).max);
        bool success = MockMarketPlaceUpgraded(marketplaceProxyAddress).buyCommonGem();
        assert(success = true);
    }

    /**
     * @dev We created a MockAirdropUpgraded and added a storage variable called counter and a function incrementCounter()
     */
    function testAirdropProxy() public {
        vm.startPrank(owner);
        mockAirdropUpgraded = new MockAirdropUpgraded();
        airdropProxy.upgradeTo(address(mockAirdropUpgraded));

        assert(MockAirdropUpgraded(airdropProxyAddress).getGemFactoryAddress() != address(0));
        assert(MockAirdropUpgraded(airdropProxyAddress).getTreasuryAddress() != address(0));

        // check that the new counter storage and incrementCounter functions are deployed
        MockAirdropUpgraded(airdropProxyAddress).incrementCounter();
        uint256 counter = MockAirdropUpgraded(airdropProxyAddress).getCounter();
        assert(counter == 1);
    }

    function testRandomPackProxy() public {
        vm.startPrank(owner);
        mockRandomPackUpgraded = new MockRandomPackUpgraded();
        randomPackProxy.upgradeTo(address(mockRandomPackUpgraded));
        
        // assert storage variable are correctly kept after the upgrade
        assert(MockRandomPackUpgraded(randomPackProxyAddress).getTreasuryAddress() != address(0));
        assert(MockRandomPackUpgraded(randomPackProxyAddress).getGemFactoryAddress() != address(0));
        assert(MockRandomPackUpgraded(randomPackProxyAddress).getTonAddress() != address(0));
        assert(MockRandomPackUpgraded(randomPackProxyAddress).getCallbackGasLimit() != 0);
        assert(MockRandomPackUpgraded(randomPackProxyAddress).getRandomPackFees() != 0);

        // check that the new counter storage and incrementCounter functions are deployed
        MockRandomPackUpgraded(randomPackProxyAddress).incrementCounter();
        uint256 counter = MockRandomPackUpgraded(randomPackProxyAddress).getCounter();
        assert(counter == 1);
    }

    /**
     * @notice upgrading GemFactory with an additionnal function `setMiningTry(uint256)`. Ensuing the function is implemented
     */
    function testGemFactoryProxy() public {
        vm.startPrank(owner);
        mockGemFactoryUpgraded = new MockGemFactoryUpgraded();
        gemfactoryProxy.upgradeTo(address(mockGemFactoryUpgraded));

        // assert storage variable are correctly kept after the upgrade
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getTreasuryAddress() == treasuryProxyAddress);
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getTonAddress() == ton);
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getWstonAddress() == wston);
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getMarketPlaceAddress() == marketplaceProxyAddress);
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getAirdropAddress() == airdropProxyAddress);
        assert(MockGemFactoryUpgraded(gemfactoryProxyAddress).getCommonGemsValue() != 0);
        
        // check that the new setRareMiningTry functions is deployed
        uint8 rareMiningTryBefore = MockGemFactoryUpgraded(gemfactoryProxyAddress).getRareminingTry();
        assert(rareMiningTryBefore == 2);
        // setting rare mining try to 10
        MockGemFactoryUpgraded(gemfactoryProxyAddress).setRareMiningTry(10);
        uint8 rareMiningTryAfter = MockGemFactoryUpgraded(gemfactoryProxyAddress).getRareminingTry();
        assert(rareMiningTryAfter == 10);

    }

    function testGemFactoryProxyRevertsIfInitializedTwice() public {
        testGemFactoryProxy();

        vm.startPrank(owner);
        
        // We expect the initialize function to revert with the selector for "InvalidInitialization()"
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        MockGemFactoryUpgraded(gemfactoryProxyAddress).initialize(
            owner,
            wston,
            ton,
            treasuryProxyAddress
        );
        vm.stopPrank();
    }
}