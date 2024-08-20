// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./L2BaseTest.sol";
import { WstonSwapPool } from "../../src/L2/WstonSwapPool.sol";

contract WstonSwap is L2BaseTest {

    address wstonSwapPool;

    uint256 public constant INITIAL_STAKING_INDEX = 10**27;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        wstonSwapPool = address(new WstonSwapPool(ton, wston, INITIAL_STAKING_INDEX, treasury));

        vm.stopPrank();

    }

    function testSetUp() public view {
        uint256 stakingIndex = WstonSwapPool(wstonSwapPool).getStakingIndex();
        uint256 tonInitialReserve = WstonSwapPool(wstonSwapPool).getTonReserve();
        uint256 wstonInitialReserve = WstonSwapPool(wstonSwapPool).getWstonReserve();

        assert(stakingIndex == INITIAL_STAKING_INDEX);
        assert(tonInitialReserve == 0);
        assert(wstonInitialReserve == 0);
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        uint256 tonAmount = 100*10**18;
        uint256 wstonAmount = 100*10**27;
        IERC20(ton).approve(wstonSwapPool, tonAmount);
        IERC20(wston).approve(wstonSwapPool, wstonAmount);
        WstonSwapPool(wstonSwapPool).addLiquidity(tonAmount, wstonAmount);
        uint256 lpshares = WstonSwapPool(wstonSwapPool).getLpShares(user1);

        // ensuring user1 received the associated shares
        assert(lpshares == tonAmount + (wstonAmount / (10**9)));
        vm.stopPrank();
    }

    function testSwapWSTONforTON() public {
        // user 1 deposit 100 TON and 100 WSTON
        testAddLiquidity();
        uint256 user1tonBalanceBefore = IERC20(ton).balanceOf(user1);

        vm.startPrank(user2);
        uint256 user2tonBalanceBefore = IERC20(ton).balanceOf(user2);

        //user wants to swap 50 WSTON for TON
        uint256 wstonAmount = 50*10**27;
        IERC20(wston).approve(wstonSwapPool, wstonAmount);
        WstonSwapPool(wstonSwapPool).swapWSTONforTON(wstonAmount);
        vm.stopPrank();

        uint256 user1tonBalanceAfter = IERC20(ton).balanceOf(user1);
        uint256 user2tonBalanceAfter = IERC20(ton).balanceOf(user2);

        uint256 tonAmount = ((wstonAmount * 10**27) / 10**27) / (10**9);
        uint256 tonFees = (tonAmount * 3) / 1000; // 0.3%
        tonAmount -= tonFees;

        // ensuring user2 received his TON
        assert(user2tonBalanceAfter == user2tonBalanceBefore + tonAmount);

        // ensureing user1 received associated fees in TON
        assert(user1tonBalanceAfter == user1tonBalanceBefore + tonFees);
    }

    function testSwapTONforWSTON() public {
        // user 1 deposit 100 TON and 100 WSTON
        testAddLiquidity();
        uint256 user1wstonBalanceBefore = IERC20(wston).balanceOf(treasury);

        vm.startPrank(treasury);
        //treasury wants to swap 50 TON for WSTON
        uint256 tonAmount = 50*10**18;
        IERC20(ton).approve(wstonSwapPool, tonAmount);
        WstonSwapPool(wstonSwapPool).swapTONforWSTON(tonAmount);

        uint256 wstonAmountSwapped = tonAmount * (10**9);
        uint256 wstonFees = (wstonAmountSwapped * 3) / 1000;
        
        //ensuring treasury received the WSTON swapped
        uint256 user1wstonBalanceAfter = IERC20(wston).balanceOf(treasury);

        assert(user1wstonBalanceAfter == user1wstonBalanceBefore + wstonAmountSwapped - wstonFees);

        vm.stopPrank;
    }

}