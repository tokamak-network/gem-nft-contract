// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L1WrappedStakedTON.t.sol";
import {MockL1WrappedStakedTONUpgraded} from "./mock/MockL1WrappedStakedTONUpgraded.sol";
import {MockL1WrappedStakedTONFactoryUpgraded} from "./mock/MockL1WrappedStakedTONFactoryUpgraded.sol";

contract L1ProxyTest is L1WrappedStakedTONTest {

    MockL1WrappedStakedTONUpgraded mockL1WrappedStakedTONUpgraded;
    MockL1WrappedStakedTONFactoryUpgraded mockL1WrappedStakedTONFactoryUpgraded;

    /**
     * @dev We created a mockL1WrappedStakedTONUpgraded contract and added a storage variable called counter and a function incrementCounter()
     */
    function testL1WrappedStakedTONFactoryProxyUpgrade() public {
        vm.startPrank(owner);

        mockL1WrappedStakedTONFactoryUpgraded = new MockL1WrappedStakedTONFactoryUpgraded();
        l1WrappedStakedtonFactoryProxy.upgradeTo(address(mockL1WrappedStakedTONFactoryUpgraded));
        
        // check that the new counter storage and incrementCounter functions are deployed
        MockL1WrappedStakedTONFactoryUpgraded(l1WrappedStakedtonFactoryProxyAddress).incrementCounter();
        uint256 counter = MockL1WrappedStakedTONFactoryUpgraded(l1WrappedStakedtonFactoryProxyAddress).getCounter();
        assert(counter == 1);

        vm.stopPrank();
    }

    /**
     * @dev testing the upgradeTo function if the caller is not the contract owner
     */
    function testL1WrappedStakedTONFactoryProxyUpgradeShouldRevertIfNotOwner() public {
        vm.startPrank(user1);

        mockL1WrappedStakedTONFactoryUpgraded = new MockL1WrappedStakedTONFactoryUpgraded();
        vm.expectRevert("AuthControl: Caller is not the owner");
        l1WrappedStakedtonFactoryProxy.upgradeTo(address(mockL1WrappedStakedTONFactoryUpgraded));

        vm.stopPrank();
    }

    /**
     * @dev We created a mockL1WrappedStakedTONUpgraded contract and added a storage variable called counter and a function incrementCounter()
     */
    function testL1WrappedStakedTONProxyUpgrade() public {
        vm.startPrank(owner);

        mockL1WrappedStakedTONUpgraded = new MockL1WrappedStakedTONUpgraded();
        // the contract is upgradeable from the L1WrappedStakedTONFactory contract only
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).upgradeWstonTo(l1wrappedstakedtonProxyAddress, address(mockL1WrappedStakedTONUpgraded));
        
        // check that the new counter storage and incrementCounter functions are deployed
        MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).incrementCounter();
        uint256 counter = MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).getCounter();
        assert(counter == 1);

        vm.stopPrank();
    }
}