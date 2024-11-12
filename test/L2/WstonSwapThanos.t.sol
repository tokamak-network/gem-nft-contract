// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import { WstonSwapPoolThanos } from "../../src/L2/WstonSwapPoolThanos.sol";
import { WstonSwapPoolStorage } from "../../src/L2/WstonSwapPoolStorage.sol";
import { WstonSwapPoolProxy } from "../../src/L2/WstonSwapPoolProxy.sol";
import { TreasuryThanos } from "../../src/L2/TreasuryThanos.sol";

contract WstonSwap is L2BaseTest {

    WstonSwapPoolThanos wstonSwapPoolThanos;
    WstonSwapPoolProxy wstonSwapPoolProxy;
    TreasuryThanos treasurythanos;
    address wstonSwapPoolProxyAddress;

    uint256 public constant INITIAL_STAKING_INDEX = 10**27;
    uint256 public constant DECIMALS = 10**27;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        wstonSwapPoolThanos = new WstonSwapPoolThanos();
        wstonSwapPoolProxy = new WstonSwapPoolProxy();
        wstonSwapPoolProxy.upgradeTo(address(wstonSwapPoolThanos));
        wstonSwapPoolProxyAddress = address(wstonSwapPoolProxy);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).initialize(
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress
        );

        treasurythanos = new TreasuryThanos();
        treasuryProxy.upgradeTo(address(treasurythanos));
        vm.deal(treasuryProxyAddress, 1000000 ether);

        TreasuryThanos(treasuryProxyAddress).setWstonSwapPool(wstonSwapPoolProxyAddress);
        assert(WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getWstonAddress() == wston);
        assert(WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getTreasuryAddress() == treasuryProxyAddress);
        assert(WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getStakingIndex() == INITIAL_STAKING_INDEX);

        vm.stopPrank();

    }

    function testSetUp() public view {
        uint256 stakingIndex = WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getStakingIndex();
        assert(stakingIndex == INITIAL_STAKING_INDEX);
    }

    // ----------------------------------- INITIALIZERS --------------------------------------

    /**
     * @notice testing the behavior of initialize function if called for the second time
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        vm.expectRevert("already initialized");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).initialize(
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress
        );
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of updateStakingIndex function
     */
    function testUpdateStakingIndex() public {
        vm.startPrank(owner);
        uint256 stakingIndex = 1063100206614753047688069608;
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
        assert(WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getStakingIndex() == stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of updateStakingIndex function if caller is not the owner
     */
    function testUpdateStakingIndexShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        uint256 stakingIndex = 1063100206614753047688069608;
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of updateStakingIndex function if caller is not the owner
     */
    function testUpdateStakingIndexShouldRevertIfWrongStakingIndex() public {
        vm.startPrank(owner);
        uint256 stakingIndex = 0;
        vm.expectRevert(WstonSwapPoolStorage.WrongStakingIndex.selector);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
        vm.stopPrank();
    }

    // ----------------------------------- CORE FUNCTIONS --------------------------------------

    /**
     * @notice testing the swap function 
     * @dev we prank user1 and call swap for 100 WSTON
     * We assert the user gets 100 TON and the treasury gets 100 WSTON (staking index = 1)
     */
    function testSwap() public {

        // calculate the TON/WSTON balance of user1 and treasury before the swap
        uint256 wstonBalanceUser1Before = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1Before = user1.balance;
        uint256 wstonBalanceTreasuryBefore = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryBefore = treasuryProxyAddress.balance;
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();

        // calculate the TON/WSTON balance of user1 and treasury after the swap
        uint256 wstonBalanceUser1After = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1After = user1.balance;
        uint256 wstonBalanceTreasuryAfter = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryAfter = treasuryProxyAddress.balance;
        // calculate the ton amount that is supposed to be transferred
        uint256 tonAmount = wstonAmount / 1e9;   

        // ensure user1 sent 100 WSTON and received 100 TON
        assert(wstonBalanceUser1After == wstonBalanceUser1Before - wstonAmount);
        assert(tonBalanceUser1After == tonBalanceUser1Before + tonAmount);

        // ensure the treasury sent 100 TON and received 100 WSTON
        assert(wstonBalanceTreasuryAfter == wstonBalanceTreasuryBefore + wstonAmount);
        assert(tonBalanceTreasuryAfter == tonBalanceTreasuryBefore - tonAmount);     
    }

    /**
     * @notice testing the swap function with an updated staking index 
     * @dev we prank user1 and call swap for 100 WSTON
     * We assert the user gets (100 * staking index) TON and the treasury gets 100 WSTON 
     */
    function testSwapWithUpdatedStakingIndex() public {
        // calculate the TON/WSTON balance of user1 and treasury before the swap
        uint256 wstonBalanceUser1Before = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1Before = user1.balance;
        uint256 wstonBalanceTreasuryBefore = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryBefore = treasuryProxyAddress.balance;

        // update the staking index
        vm.startPrank(owner);
        uint256 newStakingIndex = 1076596847394850392748594837;
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).updateStakingIndex(newStakingIndex);
        vm.stopPrank();
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();

        // calculate the TON/WSTON balance of user1 and treasury after the swap
        uint256 wstonBalanceUser1After = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1After = user1.balance;
        uint256 wstonBalanceTreasuryAfter = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryAfter = treasuryProxyAddress.balance;
        // calculate the ton amount that is supposed to be transferred
        uint256 tonAmount = ((wstonAmount * newStakingIndex) / DECIMALS) / (10**9);

        // ensure user1 sent 100 WSTON and received 100 TON
        assert(wstonBalanceUser1After == wstonBalanceUser1Before - wstonAmount);
        assert(tonBalanceUser1After == tonBalanceUser1Before + tonAmount);

        // ensure the treasury sent 100 TON and received 100 WSTON
        assert(wstonBalanceTreasuryAfter == wstonBalanceTreasuryBefore + wstonAmount);
        assert(tonBalanceTreasuryAfter == tonBalanceTreasuryBefore - tonAmount);     
    }

    /**
     * @notice testing the behavior of swap function if the treasury does not hold enough TON 
     */
    function testSwapShouldRevertIfNotEnoughFunds() public {
        // we empty the treasury TON balance (transferring to user2)
        vm.startPrank(owner);
        TreasuryThanos(treasuryProxyAddress).transferTON(user2, treasuryProxyAddress.balance);
        vm.stopPrank();
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        vm.expectRevert(WstonSwapPoolStorage.ContractTonBalanceOrAllowanceTooLow.selector);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of swap function if the allowance is too low 
     */
    function testSwapShouldRevertIfNotEnoughAllowance() public {        
        // user1 calls the swap function without approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        vm.expectRevert(WstonSwapPoolStorage.WstonAllowanceTooLow.selector);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();
    }
    
    /**
     * @notice testing the behavior of swap function if user1's wston balance is too low 
     */
    function testSwapShouldRevertIfWstonBalanceTooLow() public {
        // user1 calls the swap function with an amount greater than his balance
        vm.startPrank(user1);
        uint256 wstonAmount = 1000000 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        vm.expectRevert(WstonSwapPoolStorage.WstonBalanceTooLow.selector);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();
    }

    // ----------------------------------- PAUSE/UNPAUSE --------------------------------------

    /**
     * @notice testing the behavior of pause function
     */
    function testPause() public {
        vm.startPrank(owner);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).pause();
        assert( WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getPaused() == true);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testPauseShouldRevertIfPaused() public {
        testPause();
        vm.startPrank(owner);
        vm.expectRevert("Pausable: paused");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).unpause();
        assert( WstonSwapPoolThanos(wstonSwapPoolProxyAddress).getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).unpause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testUnpauseShouldRevertIfunpaused() public {
        vm.startPrank(owner);
        vm.expectRevert("Pausable: not paused");
        WstonSwapPoolThanos(wstonSwapPoolProxyAddress).unpause();
        vm.stopPrank();
    }

}