// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L1BaseTest.sol";
import {AuthControl} from "../../src/common/AuthControl.sol";

contract AuthControlTest is L1BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testAddAdmin() public {
        vm.startPrank(owner);
        // ensure user1 is not an admin
        assert(!L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isAdmin(user1));
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).addAdmin(user1);
        // ensure user1 is an admin
        assert(L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isAdmin(user1));
        vm.stopPrank();
    }

    function testAddAdminShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        // user1 tries to add himself as an admin
        vm.expectRevert("AuthControl: Caller is not the owner");
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).addAdmin(user1);
        vm.stopPrank();
    }

    function testRemoveAdmin() public {
        testAddAdmin();

        vm.startPrank(user1);
        // ensure user1 is an admin
        assert(L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isAdmin(user1));
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).removeAdmin();
        // ensure user1 is not an admin anymore
        assert(!L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isAdmin(user1));
        vm.stopPrank();
    }

    function testRemoveAdminShouldRevertIfNotAdmin() public {
        testAddAdmin();

        vm.startPrank(user2);
        // user2 which is not admin tries to remove his admin access
        vm.expectRevert("AuthControl: Caller is not an admin");
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).removeAdmin();
        vm.stopPrank();
    }

    function testAddPauser() public {
        testAddAdmin();
        vm.startPrank(owner);
        // user1 (admin) adds user2 as a pauser
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).addPauser(user2);
        // ensure user2 is a pauser
        assert(L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isPauser(user2));
        vm.stopPrank();
    }

    function testAddPauserShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        // user1 tries to add himself as an admin
        vm.expectRevert("AuthControl: Caller is not the owner");
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).addPauser(user1);
        vm.stopPrank();
    }

    function testRemovePauser() public {
        testAddPauser();
        vm.startPrank(user2);
        //  removes user2 as a pauser
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).removePauser(user2);
        // ensure user2 is not a pauser
        assert(!L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isPauser(user2));
        vm.stopPrank();
    }

    function testRemovePauserShouldRevertIfNotOwnerOrPauser() public {
        testAddPauser();
        vm.startPrank(user1);
        // user1 tries to remove user2 as a pauser
        vm.expectRevert("AuthControl: Caller is not a pauser");
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).removePauser(user2);
        vm.stopPrank();
    }

    function testTransferOwnership() public {
        vm.startPrank(owner);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).transferOwnership(user1);
        //ensure owner is not the owner anymore
        assert(!L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isOwner());
        vm.stopPrank();

        vm.startPrank(user1);
        // ensure user1 is the owner
        assert(L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).isOwner());
        vm.stopPrank();
    }

    function testTransferOwnershipShouldRevertIfSameOwner() public {
        vm.startPrank(owner);
        // try to transfer ownership to the same owner address
        vm.expectRevert(AuthControl.SameOwner.selector);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).transferOwnership(owner);
        vm.stopPrank();
    }

    function testTransferOwnershipShouldRevertIfAddressZero() public {
        vm.startPrank(owner);
        // try to transfer ownership to an address 0
        vm.expectRevert(AuthControl.ZeroAddress.selector);
        L1WrappedStakedTONFactory(l1WrappedStakedtonFactoryProxyAddress).transferOwnership(address(0));
        vm.stopPrank();
    }

}