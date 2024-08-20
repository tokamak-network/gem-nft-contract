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
        console.log("user1 lp shares:", lpshares);

        vm.stopPrank();
    }

    function testSwapWSTONforTON() public {
        // user 1 deposit 100 TON and 100 WSTON
        testAddLiquidity();

        vm.startPrank(user2);

        uint256 wstonAmount = 50*10**27;
        IERC20(wston).approve(wstonSwapPool, wstonAmount);
        WstonSwapPool(wstonSwapPool).swapWSTONforTON(wstonAmount);
        vm.stopPrank();
    }

}