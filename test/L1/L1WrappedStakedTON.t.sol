// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L1BaseTest.sol";

contract L1WrappedStakedTONTest is L1BaseTest {

    function setUp() public override {
        super.setUp();
    }

    // ----------------------------------- INITIALIZERS --------------------------------------

    /**
    * @notice test the behavior of initialize function if called for a second time
    */
    function testInitializeWstonContractShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        vm.expectRevert();
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).initialize(
            candidate,
            wton,
            ton,
            depositManager,
            seigManager,
            owner,
            minimumWithdrawalAmount,
            maxNumWithdrawal,
            "Titan Wrapped Staked TON",
            "Titan WSTON"
        );
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of setDepositManagerAddress function
    */
    function testsetDepositManagerAddress() public {
        vm.startPrank(owner);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).setDepositManagerAddress(address(0x1));
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getDepositManager() == address(0x1));  
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of setDepositManagerAddress function if the caller is not the owner
    */
    function testsetDepositManagerAddressShouldRevertIfNotOwner() public {
        // user1 tries to setDepositManager address
        vm.startPrank(user1);
        vm.expectRevert();
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).setDepositManagerAddress(address(0x1));
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of setSeigManagerAddress function
    */
    function testsetSeigManagerAddress() public {
        vm.startPrank(owner);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).setSeigManagerAddress(address(0x2));
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getSeigManager() == address(0x2));
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of setSeigManagerAddress function if the caller is not the owner
    */
    function testsetSeigManagerAddressShouldRevertIfNotOwner() public {
        // user1 tries to setSeigManager address
        vm.startPrank(user1);
        vm.expectRevert();
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).setSeigManagerAddress(address(0x2));
        vm.stopPrank();
    }

    // ----------------------------------- CORE FUNCTIONS -------------------------------------

    /**
    * @notice test the behavior of depositWTONAndGetWSTON function 
    */
    function testDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);

        // Call the depositAndGetWSTON function
        vm.expectEmit(true,true,true,true);
        emit L1WrappedStakedTONStorage.Deposited(user1, false, depositAmount, depositAmount, block.timestamp, block.number);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);

        //check if user's Titan WSTON balance = 200 WSTON
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).balanceOf(user1) == depositAmount);
        // check if contract balance = 200 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, address(l1wrappedstakedtonProxy)) == depositAmount);

        vm.stopPrank();
    }

    /**
    * @notice test the behavior of depositWTONAndGetWSTON function if called for the second time by another user
    * we ensure that the staking index is computing the right amount of WSTON to be minted
    */
    function testSecondDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        // Call the depositAndGetWSTON function
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);

        uint256 stakingIndex = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        uint256 wstonTotalSupply = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).totalSupply();
        uint256 sWtonBalance = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).stakeOf();
        // Recalculate expected staking index
        uint256 expectedStakingIndex = ((sWtonBalance * DECIMALS) / wstonTotalSupply) + 1;
        assert(stakingIndex == expectedStakingIndex);
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of depositWTONAndGetWSTON function if the amount passed is equal to zero
    */
    function testDepositShouldRevertIfAmountEqualToZero() public {
        vm.startPrank(user1);
        // set amount to 0
        uint256 depositAmount = 0;
        // Call the depositAndGetWSTON function
        vm.expectRevert(L1WrappedStakedTONStorage.WrontAmount.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();
    }


    /**
    * @notice test the behavior of requestWithdrawal function
    */
    function testRequestWithdrawal() public {
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
        vm.expectEmit(true,true,true,true);
        emit L1WrappedStakedTONStorage.WithdrawalRequested(user1,depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(depositAmount);
        uint256 stakingIndex = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        uint256 expectedWTONAmount = (depositAmount * stakingIndex) / DECIMALS;


        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getLastWithdrawalRequest(user1);
        assert(request.amount == expectedWTONAmount);
        assert(request.processed == false);
        assert(request.withdrawableBlockNumber == (block.number + delay));
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of requestWithdrawal function if the user does not have enough WSTON 
    */
    function testRequestWithdrawalShouldRevertIfNotEnoughWston() public {
        // deposit 200 WTON for 200 WSTON
        testDeposit();

        // trying to withdraw 201 WSTON
        uint256 withdrawalAmount = 201 * 10 ** 27;
        // Request withdrawal
        vm.expectRevert(L1WrappedStakedTONStorage.NotEnoughFunds.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(withdrawalAmount);
    }

    /**
    * @notice test the behavior of claimWithdrawalTotal function 
    */
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

        uint256 tonBalanceBefore = IERC20(ton).balanceOf(user1);
        uint256 stakingIndexBefore = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();

        // expected amount to be received ===> check the emit event to see if it's corresponding
        uint256 tonAmountReceived = (depositAmount * stakingIndexBefore) / 1e36;

        vm.expectEmit(true,true,true,true);
        emit L1WrappedStakedTONStorage.WithdrawalProcessed(user1, tonAmountReceived);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal();
        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getWithdrawalRequest(user1, 0);
       
        //checking the staking index is not affected
        uint256 stakingIndexAfter = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        assert(stakingIndexAfter == stakingIndexBefore);
        assert(IERC20(ton).balanceOf(user1) == tonBalanceBefore + tonAmountReceived);
        assert(request.processed == true);

        vm.stopPrank();
    }

    /**
    * @notice test the behavior of claimWithdrawalTotal function 
    */
    function testClaimWithdrawalTotalShouldRevertIfNoClaimableAmount() public {
        // deposit, request withdrawal and claim total
        testClaimWithdrawalTotal();

        vm.startPrank(user1);
        // trying to reclaim
       vm.expectRevert(
            abi.encodeWithSelector(
                L1WrappedStakedTONStorage.NoClaimableAmount.selector,
                user1
            )
        );
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal();
        vm.stopPrank();
    }

    /**
    * @notice test the behavior of claimWithdrawalIndex function 
    */
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

        uint256 tonBalanceBefore = IERC20(ton).balanceOf(user1);
        //1007868027750759615961946603
        uint256 stakingIndexBefore = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();


        // calculate the amount expected to be sent ( in WTON)
        uint256 amountToBeSend = (secondWithdrawalAmount * stakingIndexBefore) / 1e36;
        // Claim the withdrawal by index
        vm.expectEmit(true,true,true,true);
        emit L1WrappedStakedTONStorage.WithdrawalProcessed(user1, amountToBeSend);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(1);

        L1WrappedStakedTONStorage.WithdrawalRequest memory request = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getWithdrawalRequest(user1, 1);
        // Check that the staking index is not affected
        uint256 stakingIndexAfter = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        assert(stakingIndexAfter == stakingIndexBefore);

        // Check that the user's balance is updated correctly
        assert(IERC20(ton).balanceOf(user1) == tonBalanceBefore + amountToBeSend);
        assert(request.processed == true);

        vm.stopPrank();
    }

    function testClaimWithdrawalIndexShouldRevertIfWrongRequestIndex() public {
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

        // Claim the withdrawal with index = 2 ===> should revert
        vm.expectRevert(L1WrappedStakedTONStorage.NoRequestToProcess.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(2);
        vm.stopPrank();
    }

    function testClaimWithdrawalIndexShouldRevertIfAlreadyProcessed() public {
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

        //1007868027750759615961946603
        uint256 stakingIndexBefore = L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getStakingIndex();
        // calculate the amount expected to be sent ( in WTON)
        uint256 amountToBeSend = (secondWithdrawalAmount * stakingIndexBefore) / 1e36;
        // Claim the withdrawal with index = 1
        vm.expectEmit(true,true,true,true);
        emit L1WrappedStakedTONStorage.WithdrawalProcessed(user1, amountToBeSend);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(1);

        // try to reclain the same index
        vm.expectRevert(L1WrappedStakedTONStorage.RequestAlreadyProcessed.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(1);
        vm.stopPrank();
    }

    function testClaimWithdrawalIndexShouldRevertIfDelayNotElapsed() public {
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

        // rolling up to 1 block before due date
        vm.roll(block.number + delay - 1);
        vm.expectRevert(L1WrappedStakedTONStorage.WithdrawalDelayNotElapsed.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalIndex(1);
    }

    /**
    * @notice this tests aims to prove that if 2 different user request withdrawal and one of them claimWithdrawal, 
    * the second user is still able to claimWithdrawal 
    */
    function testClaimWithdrawalByTwoDifferentUsers() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // user2 deposits
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 200000 block
        vm.roll(block.number + 200000);

        // user1 withdrawal request
        vm.startPrank(user1);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(minimumWithdrawalAmount);
        vm.stopPrank();

        // user2 withdrawal request
        vm.startPrank(user2);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(depositAmount);
        vm.stopPrank();

        // rolling up to 1 block before due date
        vm.roll(block.number + delay);

        // user1 claim withdrawal
        vm.startPrank(user2);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal();
        vm.stopPrank();

        // user1 claim withdrawal
        vm.startPrank(user1);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal();
        vm.stopPrank();
    }

    /**
    * @notice checking if requestWithdrawal reverts if the caller has already reached the maximum withdrawals limit
    */
    function testrequestWithdrawalShouldRevertIfTooManyRequests() public {
        // user1 deposit
        vm.startPrank(user1);
        uint256 depositAmount = 100000 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);


        // move to the next 200000 block
        vm.roll(block.number + 200000);

        // requesting 1 request less than the limit
        for (uint i = 0; i < maxNumWithdrawal; ++i) {
            L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(10 * 1e27);
        }

        // attempting the request another time
        vm.expectRevert(L1WrappedStakedTONStorage.MaximumNumberOfWithdrawalsReached.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(10 * 1e27);
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
    
    /**
    * @notice testing the behavior of onApprove function
    */
    function testOnApprove() public {
        vm.startPrank(user1);
        uint256 tonDepositAmount = 100 * 10**18;
        bytes memory data = abi.encode(user1, tonDepositAmount);

        //approving the proxy to spend TON
        TON(ton).approve(address(l1wrappedstakedtonProxy), tonDepositAmount);

        bool success = TON(ton).approveAndCall(address(l1wrappedstakedtonProxy), tonDepositAmount, data);
        require(success);
        vm.stopPrank();

        //check if user's Titan WSTON balance = 100 WSTON
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).balanceOf(user1) == tonDepositAmount * 1e9);
        // check if contract balance = 100 sWTON
        assert(SeigManager(seigManager).stakeOf(candidate, address(l1wrappedstakedtonProxy)) == tonDepositAmount * 1e9);
    }

    /**
    * @notice testing the behavior of onApprove function if the caller is neither TON or WTON addresses
    */
    function testOnApproveShouldRevertIfCalledByWrongContract() public {
        vm.startPrank(user1);
        uint256 tonDepositAmount = 100 * 10**18;
        bytes memory data = abi.encode(user1, tonDepositAmount);
        // try to call onApprove using user1 EOA
        vm.expectRevert(L1WrappedStakedTONStorage.InvalidCaller.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).onApprove(
            user1,
            user1,
            tonDepositAmount,
            data
        );
        vm.stopPrank();
    }

    /**
    * @notice testing the behavior of onApprove function if the caller is neither TON or WTON addresses
    */
    function testOnApproveShouldRevertIfInvalidData() public {
        vm.startPrank(user1);
        uint256 tonDepositAmount = 100 * 10**18;
        uint256 dummyData = 1;
        bytes memory data = abi.encode(user1, tonDepositAmount, dummyData);
        // try to call onApprove using user1 EOA
         //approving the proxy to spend TON
        TON(ton).approve(address(l1wrappedstakedtonProxy), tonDepositAmount);

        vm.expectRevert(L1WrappedStakedTONStorage.InvalidOnApproveData.selector);
        TON(ton).approveAndCall(address(l1wrappedstakedtonProxy), tonDepositAmount, data);

        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of numWithdrawableRequests
     * User1 and user2 both deposit 200 WTON
     * User1 makes 2 withdrawal requests for 100 WSTON each. User2 makes 1 withdrawal request for 100 WSTON
     * We roll after the delay and user1 claimsWithdrawal. numWithdrawableRequests should return 3
     * @dev we manually calculate each variable of the function to check if it is in accordance
     */
    function testNumWithdrawableRequests() public {
        // user1 deposit 200 WTON
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10**27;
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user2 deposits 200 WTON
        vm.startPrank(user2);
        WTON(wton).approve(address(l1wrappedstakedtonProxy), depositAmount);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).depositWTONAndGetWSTON(depositAmount, false);
        vm.stopPrank();

        // move to the next 100000 block
        vm.roll(block.number + 100000);

        // user1 makes 2 withdrawal requests for a total of 100 WSTON
        vm.startPrank(user1);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(50*1e27);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(50*1e27);
        vm.stopPrank();

        // move to the next 1000000 block
        vm.roll(block.number + 1000000);

        // user1 claims withdrawal
        vm.startPrank(user1);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).claimWithdrawalTotal();
        vm.stopPrank();

        // user2 makes 2 withdrawals requests for a total of 100 WSTON
        vm.startPrank(user2);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(50*1e27);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).requestWithdrawal(50*1e27);
        vm.stopPrank();

        // move to the next 1000000 block
        vm.roll(block.number + 1000000);

        /// at this stage we got a total of 2 requests that are withdrawable
        /// we manually calculate the count variable from numWithdrawableRequests
        uint256 numRequests = DepositManager(depositManager).numRequests(candidate, address(l1wrappedstakedtonProxy)); // should be equal to 4
        uint256 index = DepositManager(depositManager).withdrawalRequestIndex(candidate, address(l1wrappedstakedtonProxy)); // should be equal to 2
        uint256 numberPendingRequests = numRequests - index; // should be equal to 2
        uint256 count;
        for(uint256 i = 0; i < numberPendingRequests; ++i) {
            (uint128 withdrawableBlockNumber,,bool processed) = DepositManager(depositManager).withdrawalRequest(candidate, address(l1wrappedstakedtonProxy), index + i);
            if(withdrawableBlockNumber <= block.number && !processed) {
                count++;
            }
        }
        console.log("count: ", count);
        assert(count == 2);

    }

    // ----------------------------------- PAUSE/UNPAUSE --------------------------------------

    /**
     * @notice testing the behavior of pause function
     */
    function testPause() public {
        vm.startPrank(owner);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).pause();
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getPaused() == true);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert();
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testPauseShouldRevertIfPaused() public {
        testPause();
        vm.startPrank(owner);
        vm.expectRevert(L1WrappedStakedTONStorage.ContractPaused.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).unpause();
        assert(L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert();
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).unpause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testUnpauseShouldRevertIfunpaused() public {
        vm.startPrank(owner);
        vm.expectRevert(L1WrappedStakedTONStorage.ContractNotPaused.selector);
        L1WrappedStakedTON(address(l1wrappedstakedtonProxy)).unpause();
        vm.stopPrank();
    }
    
}