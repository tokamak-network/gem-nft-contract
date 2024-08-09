// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./L1BaseTest.sol";

contract WrappedStakedTONTest is L1BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(l1wrappedstakedton).depositAndGetWSTON(depositAmount);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(l1wrappedstakedton).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, l1wrappedstakedton) == depositAmount);

        vm.stopPrank();
    }

    function testSecondDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(l1wrappedstakedton).depositAndGetWSTON(depositAmount);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(l1wrappedstakedton).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, l1wrappedstakedton) == depositAmount);

        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);

        Candidate(candidate).updateSeigniorage();

        console.log("sWTON contract balance before = ", L1WrappedStakedTON(l1wrappedstakedton).stakeOf());
        console.log("total WSTON supply before = ", L1WrappedStakedTON(l1wrappedstakedton).totalSupply());

        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositAndGetWSTON(depositAmount);

        console.log("user1 WSTON balance: ", L1WrappedStakedTON(l1wrappedstakedton).balanceOf(user1));
        console.log("user2 WSTON balance: ", L1WrappedStakedTON(l1wrappedstakedton).balanceOf(user2));
        console.log("sWTON contract balance = ", SeigManager(seigManager).stakeOf(candidate, l1wrappedstakedton));
        console.log("staking index = ", L1WrappedStakedTON(l1wrappedstakedton).getStakingIndex());
        console.log("total WSTON supply = ", L1WrappedStakedTON(l1wrappedstakedton).totalSupply());

        vm.stopPrank();
    }
    
}