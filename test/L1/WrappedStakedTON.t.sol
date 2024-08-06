// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./L1BaseTest.sol";

contract WrappedStakedTONTest is L1BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testDepositAndGetWSTON() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        IERC20(l1wton).approve(l1wrappedstakedton, depositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(l1wrappedstakedton).depositAndGetWSTON(depositAmount, 0);

        vm.stopPrank();
    }
}