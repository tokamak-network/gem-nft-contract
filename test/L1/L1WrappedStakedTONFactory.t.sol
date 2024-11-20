// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L1BaseTest.sol";
import {MockL1WrappedStakedTONUpgraded} from "./mock/MockL1WrappedStakedTONUpgraded.sol";
import { L1WrappedStakedTONFactoryStorage } from "../../src/L1/L1WrappedStakedTONFactoryStorage.sol";


contract L1WrappedStakedTONFactoryTest is L1BaseTest {

    MockL1WrappedStakedTONUpgraded mockL1WrappedStakedTONUpgraded;

    function setUp() public override {
        super.setUp();
    }

    function testInitialize() public {
        // Test re-initialization
        vm.expectRevert(L1WrappedStakedTONFactoryStorage.AlreadyInitialized.selector);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).initialize(address(0x1), address(0x2));
    }

    function testCreateWSTONToken() public {
        // Test with valid inputs
        vm.startPrank(owner);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).createWSTONToken(
            address(0x3), 
            address(0x4), 
            address(0x5), 
            minimumWithdrawalAmount, 
            maxNumWithdrawal,
            "Token", 
            "TKN"
        );

        // Test with zero address
        vm.expectRevert("Address cannot be zero");
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).createWSTONToken(
            address(0), 
            address(0x4), 
            address(0x5),
            minimumWithdrawalAmount, 
            maxNumWithdrawal, 
            "Token", 
            "TKN"
        );
        vm.stopPrank();

        // Test with non-admin
        vm.startPrank(user1);
        vm.expectRevert("not Owner or Admin");
         L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).createWSTONToken(
            address(0x3), 
            address(0x4), 
            address(0x5), 
            minimumWithdrawalAmount, 
            maxNumWithdrawal, 
            "Token", 
            "TKN"
        );

    }

    function testSetWstonImplementation() public {
        // Test setting implementation
        vm.prank(owner);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).setWstonImplementation(address(0x6));

        // Test unauthorized access
        vm.expectRevert("AuthControl: Caller is not the owner");
        vm.prank(user1);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).setWstonImplementation(address(0x7));
    }

    function testUpgradeWstonTo() public {

        vm.startPrank(owner);
        mockL1WrappedStakedTONUpgraded = new MockL1WrappedStakedTONUpgraded();
        // the contract is upgradeable from the L1WrappedStakedTONFactory contract only
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).upgradeWstonTo(l1wrappedstakedtonProxyAddress, address(mockL1WrappedStakedTONUpgraded));
        
        // check that the new counter storage and incrementCounter functions are deployed
        address l1wrappedstakedtonProxyAddress = l1wrappedstakedtonProxyAddress;
        MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).incrementCounter();
        uint256 counter = MockL1WrappedStakedTONUpgraded(l1wrappedstakedtonProxyAddress).getCounter();
        assert(counter == 1);
        vm.stopPrank();

        // Test upgrade with incorrect owner
        vm.startPrank(user1);
        vm.expectRevert(L1WrappedStakedTONFactoryStorage.NotContractOwner.selector);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).upgradeWstonTo(l1wrappedstakedtonProxyAddress, address(0x9));
        vm.stopPrank();
    }


}