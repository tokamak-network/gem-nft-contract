// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);

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
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(l1wrappedstakedton).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, l1wrappedstakedton) == depositAmount);

        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);

        //Candidate(candidate).updateSeigniorage();

        //console.log("sWTON contract balance before = ", L1WrappedStakedTON(l1wrappedstakedton).stakeOf());
        //console.log("total WSTON supply before = ", L1WrappedStakedTON(l1wrappedstakedton).totalSupply());

        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);

        uint256 stakingIndex = L1WrappedStakedTON(l1wrappedstakedton).stakingIndex();
        uint256 wstonTotalSupply = L1WrappedStakedTON(l1wrappedstakedton).getTotalWSTONSupply();
        uint256 sWtonBalance = L1WrappedStakedTON(l1wrappedstakedton).stakeOf();

        //console.log("staking index = ", stakingIndex);
        //console.log("total WSTON supply = ", wstonTotalSupply);
        //console.log("sWTON contract balance = ", sWtonBalance);

        // Recalculate expected staking index
        uint256 expectedStakingIndex = ((sWtonBalance * DECIMALS) / wstonTotalSupply) + 1;
        //console.log("expected staking index = ", expectedStakingIndex);

        assert(stakingIndex == expectedStakingIndex);

        vm.stopPrank();
    }

    function testDepositAndRequestWithdrawal() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 withdrawal request
        vm.startPrank(user1);
        // Request withdrawal
        L1WrappedStakedTON(l1wrappedstakedton).requestWithdrawal(depositAmount);
        uint256 stakingIndex = L1WrappedStakedTON(l1wrappedstakedton).stakingIndex();
        uint256 expectedWTONAmount = (depositAmount * stakingIndex) / DECIMALS;


        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(l1wrappedstakedton).getLastWithdrawalRequest(user1);

        //console.log("staking index: ", stakingIndex);
        //console.log("expected withdrawal amount: ", expectedWTONAmount);
        //console.log("actual withdrawal amount: ", request.amount);
        assert(request.amount == expectedWTONAmount);
        assert(request.processed == false);
        assert(request.withdrawableBlockNumber == (block.number + delay));
        vm.stopPrank();
    }

    function testClaimWithdrawal() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        IERC20(wton).approve(l1wrappedstakedton, depositAmount);
        L1WrappedStakedTON(l1wrappedstakedton).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 withdrawal request
        vm.startPrank(user1);
        // Request withdrawal
        L1WrappedStakedTON(l1wrappedstakedton).requestWithdrawal(depositAmount);

        vm.roll(block.number + delay);

        uint256 wtonBalanceBefore = IERC20(wton).balanceOf(user1);
        uint256 stakingIndexBefore = L1WrappedStakedTON(l1wrappedstakedton).stakingIndex();

        L1WrappedStakedTON(l1wrappedstakedton).claimWithdrawalTotal(false);
        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(l1wrappedstakedton).getWithdrawalRequest(user1, 0);
       
        //checking the staking index is not affected
        uint256 stakingIndexAfter = L1WrappedStakedTON(l1wrappedstakedton).stakingIndex();
        assert(stakingIndexAfter == stakingIndexBefore);


        // balance before = 9800.000000000000000000000000000
        // request.amount = 201.573605550151923192389320400
        // balance after =  10001.573605550151923192389320400
        assert(IERC20(wton).balanceOf(user1) == wtonBalanceBefore + request.amount);
        assert(request.processed == true);

        vm.stopPrank();
    }
    
}