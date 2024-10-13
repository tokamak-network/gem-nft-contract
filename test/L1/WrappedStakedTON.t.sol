// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L1BaseTest.sol";

contract WrappedStakedTONTest is L1BaseTest {

    function setUp() public override {
        super.setUp();
    }

    function testDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, address(l1wrappedstakedtonProxy)) == depositAmount);

        vm.stopPrank();
    }

    function testSecondDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, address(l1wrappedstakedtonProxy)) == depositAmount);

        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);

        //Candidate(candidate).updateSeigniorage();

        //console.log("sWTON contract balance before = ", l1wrappedstakedtonProxy(l1wrappedstakedtonProxy).stakeOf());
        //console.log("total WSTON supply before = ", l1wrappedstakedtonProxy(l1wrappedstakedtonProxy).totalSupply());

        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);

        uint256 stakingIndex = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        uint256 wstonTotalSupply = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).totalSupply();
        uint256 sWtonBalance = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).stakeOf();

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
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 withdrawal request
        vm.startPrank(user1);
        // Request withdrawal
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(depositAmount);
        uint256 stakingIndex = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        uint256 expectedWTONAmount = (depositAmount * stakingIndex) / DECIMALS;


        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getLastWithdrawalRequest(user1);

        //console.log("staking index: ", stakingIndex);
        //console.log("expected withdrawal amount: ", expectedWTONAmount);
        //console.log("actual withdrawal amount: ", request.amount);
        assert(request.amount == expectedWTONAmount);
        assert(request.processed == false);
        assert(request.withdrawableBlockNumber == (block.number + delay));
        vm.stopPrank();
    }

    function testClaimWithdrawalTotal() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 withdrawal request
        vm.startPrank(user1);
        // Request withdrawal
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(depositAmount);

        vm.roll(block.number + delay);

        uint256 wtonBalanceBefore = IERC20(wton).balanceOf(user1);
        uint256 stakingIndexBefore = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();

        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal(false);
        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getWithdrawalRequest(user1, 0);
       
        //checking the staking index is not affected
        uint256 stakingIndexAfter = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        assert(stakingIndexAfter == stakingIndexBefore);


        // balance before = 9800.000000000000000000000000000
        // request.amount = 201.573605550151923192389320400
        // balance after =  10001.573605550151923192389320400
        assert(IERC20(wton).balanceOf(user1) == wtonBalanceBefore + request.amount);
        assert(request.processed == true);

        vm.stopPrank();
    }

    function testClaimWithdrawalIndex() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 withdrawal request
        vm.startPrank(user1);
        // Making 2 withdrawal requests. one is 50 WSTON the other is 10 WSTON
        uint256 firstWithdrawalAmount = 50*10**27;
        uint256 secondWithdrawalAmount = 10*10**27;
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(firstWithdrawalAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(secondWithdrawalAmount);

        vm.roll(block.number + delay);

        uint256 wtonBalanceBefore = IERC20(wton).balanceOf(user1);
        //881390845570101520291980348
        uint256 stakingIndexBefore = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();

        // Claim the withdrawal by index
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(1, false);
        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getWithdrawalRequest(user1, 1);

        // Check that the staking index is not affected
        uint256 stakingIndexAfter = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        assert(stakingIndexAfter == stakingIndexBefore);

        // Check that the user's balance is updated correctly
        assert(IERC20(wton).balanceOf(user1) == wtonBalanceBefore + request.amount);
        assert(request.processed == true);

        vm.stopPrank();
    }


    function testDepositUsingTON() public {
        vm.startPrank(user1);
        uint256 tonDepositAmount = 200 * 10**18;
        TON(ton).approve(address(l1wrappedstakedtonProxy), tonDepositAmount);

        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(tonDepositAmount, true);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).balanceOf(user1) == tonDepositAmount * 1e9);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, address(l1wrappedstakedtonProxy)) == tonDepositAmount * 1e9);

        vm.stopPrank();
    }
    
}