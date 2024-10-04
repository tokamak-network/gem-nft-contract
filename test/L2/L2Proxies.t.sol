// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./WstonSwap.t.sol";
import {MockSwapPoolUpgraded} from "./mock/MockSwapPoolUpgraded.sol";
import {MockTreasuryUpgraded} from "./mock/MockTreasuryUpgraded.sol";
import {MockMarketPlaceUpgraded} from "./mock/MockMarketPlaceUpgraded.sol";
import {MockAirdropUpgraded} from "./mock/MockAirdropUpgraded.sol";

contract L2ProxyTest is WstonSwap {

    MockSwapPoolUpgraded mockSwapPoolUpgraded; 
    MockTreasuryUpgraded mockTreasuryUpgraded;
    MockMarketPlaceUpgraded mockMarketPlaceUpgraded;
    MockAirdropUpgraded mockAirdropUpgraded;
    
    /**
     * @dev We created a MockSwapPoolUpgraded and added a function called resetFees() which can only be called by the owner
     */
    function testWstonSwapPoolProxyUpgrade() public {
        // we replay the scenario where LP deposit and user1 swaps
        testSwapWSTONforTONWithUpdatedStakingIndex();

        //we add liquidity and perform swap operations to ensure wstonFeesBalance != 0
        vm.startPrank(owner);
        uint256 tonAmount = 100*10**18;
        Treasury(treasuryProxyAddress).tonApproveWstonSwapPool();
        Treasury(treasuryProxyAddress).swapTONforWSTON(tonAmount);

        // we upgrade the swapper
        vm.startPrank(owner);
        mockSwapPoolUpgraded = new MockSwapPoolUpgraded();
        wstonSwapPoolProxy.upgradeTo(address(mockSwapPoolUpgraded));


        // we ensure that old storage variables were kept 
        uint256 stakingIndex = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getStakingIndex();
        assert(stakingIndex != 0);
        uint256 tonReserve = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getTonReserve();
        assert(tonReserve != 0);
        uint256 wstonReserve = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getWstonReserve();
        assert(wstonReserve != 0);
        uint256 totalShares = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getTotalShares();
        assert(totalShares != 0);

        uint256 wstonFeesBalanceBefore = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getWstonFeesBalance();
        assert(wstonFeesBalanceBefore != 0);
        
        // we ensure the new implementation is considered by calling resetFee();
        MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).resetFees();
        uint256 wstonFeesBalanceAfter = MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).getWstonFeesBalance();
        assert(wstonFeesBalanceAfter == 0);

        vm.stopPrank();
    }

    /**
     * @dev The test tries to upgrade the WstonSwapPool contract using user1 account (not the owner). We expect it to revert
     */
    function testWstonSwapPoolProxyUpgradeRevertsIfNotOwner() public {
        // we replay the scenario where LP deposit and user1 swaps
        testSwapWSTONforTONWithUpdatedStakingIndex();
        
        // we try to upgrade the swapper using user1 account
        vm.startPrank(user1);
        mockSwapPoolUpgraded = new MockSwapPoolUpgraded();
        
        // we expect the upgradeTo function to revert
        vm.expectRevert("AuthControl: Caller is not the owner");
        wstonSwapPoolProxy.upgradeTo(address(mockSwapPoolUpgraded));

        vm.stopPrank();
    }

    function testProxyInitializeRevertsIfCalledTwice() public {
        testWstonSwapPoolProxyUpgrade();

        vm.startPrank(owner);

        // we expect the initialize function to revert
        vm.expectRevert("already initialized");
        MockSwapPoolUpgraded(wstonSwapPoolProxyAddress).initialize(
            ton,
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress,
            feeRate
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
}