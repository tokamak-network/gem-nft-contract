// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import { WstonSwapPool } from "../../src/L2/WstonSwapPool.sol";
import { WstonSwapPoolStorage } from "../../src/L2/WstonSwapPoolStorage.sol";
import { WstonSwapPoolProxy } from "../../src/L2/WstonSwapPoolProxy.sol";

contract WstonSwap is L2BaseTest {

    WstonSwapPool wstonSwapPool;
    WstonSwapPoolProxy wstonSwapPoolProxy;
    address wstonSwapPoolProxyAddress;

    uint256 public constant INITIAL_STAKING_INDEX = 10**27;
    uint256 public constant DECIMALS = 10**27;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        wstonSwapPool = new WstonSwapPool();
        wstonSwapPoolProxy = new WstonSwapPoolProxy();
        wstonSwapPoolProxy.upgradeTo(address(wstonSwapPool));
        wstonSwapPoolProxyAddress = address(wstonSwapPoolProxy);
        WstonSwapPool(wstonSwapPoolProxyAddress).initialize(
            ton,
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress
        );
        Treasury(treasuryProxyAddress).setWstonSwapPool(wstonSwapPoolProxyAddress);
        assert(WstonSwapPool(wstonSwapPoolProxyAddress).getTonAddress() == ton);
        assert(WstonSwapPool(wstonSwapPoolProxyAddress).getWstonAddress() == wston);
        assert(WstonSwapPool(wstonSwapPoolProxyAddress).getTreasuryAddress() == treasuryProxyAddress);
        assert(WstonSwapPool(wstonSwapPoolProxyAddress).getStakingIndex() == INITIAL_STAKING_INDEX);

        vm.stopPrank();

    }

    function testSetUp() public view {
        uint256 stakingIndex = WstonSwapPool(wstonSwapPoolProxyAddress).getStakingIndex();
        assert(stakingIndex == INITIAL_STAKING_INDEX);
    }

    // ----------------------------------- INITIALIZERS --------------------------------------

    /**
     * @notice testing the behavior of initialize function if called for the second time
     */
    function testInitializeShouldRevertIfCalledTwice() public {
        vm.startPrank(owner);
        vm.expectRevert("already initialized");
        WstonSwapPool(wstonSwapPoolProxyAddress).initialize(
            ton,
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
        WstonSwapPool(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
        assert(WstonSwapPool(wstonSwapPoolProxyAddress).getStakingIndex() == stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of updateStakingIndex function if caller is not the owner
     */
    function testUpdateStakingIndexShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        uint256 stakingIndex = 1063100206614753047688069608;
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPool(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of updateStakingIndex function if caller is not the owner
     */
    function testUpdateStakingIndexShouldRevertIfWrongStakingIndex() public {
        vm.startPrank(owner);
        uint256 stakingIndex = 0;
        vm.expectRevert(WstonSwapPoolStorage.WrongStakingIndex.selector);
        WstonSwapPool(wstonSwapPoolProxyAddress).updateStakingIndex(stakingIndex);
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
        uint256 tonBalanceUser1Before = IERC20(ton).balanceOf(user1);
        uint256 wstonBalanceTreasuryBefore = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryBefore = IERC20(ton).balanceOf(treasuryProxyAddress);
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();

        // calculate the TON/WSTON balance of user1 and treasury after the swap
        uint256 wstonBalanceUser1After = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1After = IERC20(ton).balanceOf(user1);
        uint256 wstonBalanceTreasuryAfter = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryAfter = IERC20(ton).balanceOf(treasuryProxyAddress);
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
        uint256 tonBalanceUser1Before = IERC20(ton).balanceOf(user1);
        uint256 wstonBalanceTreasuryBefore = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryBefore = IERC20(ton).balanceOf(treasuryProxyAddress);

        // update the staking index
        vm.startPrank(owner);
        uint256 newStakingIndex = 1076596847394850392748594837;
        WstonSwapPool(wstonSwapPoolProxyAddress).updateStakingIndex(newStakingIndex);
        vm.stopPrank();
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();

        // calculate the TON/WSTON balance of user1 and treasury after the swap
        uint256 wstonBalanceUser1After = IERC20(wston).balanceOf(user1);
        uint256 tonBalanceUser1After = IERC20(ton).balanceOf(user1);
        uint256 wstonBalanceTreasuryAfter = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonBalanceTreasuryAfter = IERC20(ton).balanceOf(treasuryProxyAddress);
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
        Treasury(treasuryProxyAddress).transferTON(user2, IERC20(ton).balanceOf(treasuryProxyAddress));
        vm.stopPrank();
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        vm.expectRevert(WstonSwapPoolStorage.ContractTonBalanceOrAllowanceTooLow.selector);
        WstonSwapPool(wstonSwapPoolProxyAddress).swap(wstonAmount);
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
        WstonSwapPool(wstonSwapPoolProxyAddress).swap(wstonAmount);
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
        WstonSwapPool(wstonSwapPoolProxyAddress).swap(wstonAmount);
        vm.stopPrank();
    }

    // ----------------------------------- PAUSE/UNPAUSE --------------------------------------

    /**
     * @notice testing the behavior of pause function
     */
    function testPause() public {
        vm.startPrank(owner);
        WstonSwapPool(wstonSwapPoolProxyAddress).pause();
        assert( WstonSwapPool(wstonSwapPoolProxyAddress).getPaused() == true);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of pause function if called by user1
     */
    function testPauseShouldRevertIfNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPool(wstonSwapPoolProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testPauseShouldRevertIfPaused() public {
        testPause();
        vm.startPrank(owner);
        vm.expectRevert("Pausable: paused");
        WstonSwapPool(wstonSwapPoolProxyAddress).pause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function
     */
    function testUnpause() public {
        testPause();
        vm.startPrank(owner);
        WstonSwapPool(wstonSwapPoolProxyAddress).unpause();
        assert( WstonSwapPool(wstonSwapPoolProxyAddress).getPaused() == false);
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if called by user1
     */
    function testUnpauseShouldRevertIfNotOwner() public {
        testPause();
        vm.startPrank(user1);
        vm.expectRevert("AuthControl: Caller is not the owner");
        WstonSwapPool(wstonSwapPoolProxyAddress).unpause();
        vm.stopPrank();
    }

    /**
     * @notice testing the behavior of unpause function if already unpaused
     */
    function testUnpauseShouldRevertIfunpaused() public {
        vm.startPrank(owner);
        vm.expectRevert("Pausable: not paused");
        WstonSwapPool(wstonSwapPoolProxyAddress).unpause();
        vm.stopPrank();
    }

}