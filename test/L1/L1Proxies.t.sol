// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./WrappedStakedTON.t.sol";
import {MockL1WrappedStakedTONUpgraded} from "./mock/MockL1WrappedStakedTONUpgraded.sol";

contract L1ProxyTest is WrappedStakedTONTest {

    MockL1WrappedStakedTONUpgraded mockL1WrappedStakedTONUpgraded;

    /**
     * @dev We created a mockL1WrappedStakedTONUpgraded contract and added a storage variable called counter and a function incrementCounter()
     */
    function testL1WrappedStakedTONProxyUpgrade() public {
        vm.startPrank(owner);

        mockL1WrappedStakedTONUpgraded = new MockL1WrappedStakedTONUpgraded();
        L1WrappedStakedTONFactory(l1wrappedstakedtonFactory).upgradeWstonTo(address(l1wrappedstakedtonProxy), address(mockL1WrappedStakedTONUpgraded));
        
        // check that the new counter storage and incrementCounter functions are deployed
        address l1wrappedstakedtonProxyAddress = address(l1wrappedstakedtonProxy);
        MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).incrementCounter();
        uint256 counter = MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).getCounter();
        assert(counter == 1);

        vm.stopPrank();
    }
}