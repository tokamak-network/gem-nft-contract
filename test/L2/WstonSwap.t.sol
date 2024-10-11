// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import { WstonSwapPool } from "../../src/L2/WstonSwapPool.sol";
import { WstonSwapPoolProxy } from "../../src/L2/WstonSwapPoolProxy.sol";

contract WstonSwap is L2BaseTest {

    WstonSwapPool wstonSwapPool;
    WstonSwapPoolProxy wstonSwapPoolProxy;
    address wstonSwapPoolProxyAddress;

    uint256 public constant INITIAL_STAKING_INDEX = 10**27;
    uint256 public feeRate = 30; // 0.3%

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
            treasuryProxyAddress,
            feeRate
        );

        Treasury(treasuryProxyAddress).setWstonSwapPool(wstonSwapPoolProxyAddress);

        vm.stopPrank();

    }

    function testSetUp() public view {
        uint256 stakingIndex = WstonSwapPool(wstonSwapPoolProxyAddress).getStakingIndex();
        uint256 tonInitialReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getTonReserve();
        uint256 wstonInitialReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getWstonReserve();

        assert(stakingIndex == INITIAL_STAKING_INDEX);
        assert(tonInitialReserve == 0);
        assert(wstonInitialReserve == 0);
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        uint256 tonAmount = 1000*10**18;
        uint256 wstonAmount = 1000*10**27;
        IERC20(ton).approve(wstonSwapPoolProxyAddress, tonAmount);
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).addLiquidity(tonAmount, wstonAmount);
        uint256 lpshares = WstonSwapPool(wstonSwapPoolProxyAddress).getLpShares(user1);

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
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swapWSTONforTON(wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();
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
        uint256 treasurywstonBalanceBefore = IERC20(wston).balanceOf(treasuryProxyAddress);

        vm.startPrank(treasuryProxyAddress);
        //treasury wants to swap 50 TON for WSTON
        uint256 tonAmount = 50*10**18;
        IERC20(ton).approve(wstonSwapPoolProxyAddress, tonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swapTONforWSTON(tonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();

        uint256 wstonAmountSwapped = tonAmount * (10**9);
        uint256 wstonFees = (wstonAmountSwapped * 3) / 1000;
        
        //ensuring treasury received the WSTON swapped
        uint256 treasurywstonBalanceAfter = IERC20(wston).balanceOf(treasuryProxyAddress);

        assert(treasurywstonBalanceAfter == treasurywstonBalanceBefore + wstonAmountSwapped - wstonFees);

        vm.stopPrank;
    }

    function testRemoveLiquidity() public {
        testSwapWSTONforTON();

        vm.startPrank(user1);
        uint256 user1Shares = WstonSwapPool(wstonSwapPoolProxyAddress).getLpShares(user1);
        uint256 wstonReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getWstonReserve();
        uint256 tonReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getTonReserve();

        uint256 user1wstonBalanceBefore = IERC20(wston).balanceOf(user1);
        uint256 user1tonBalanceBefore = IERC20(ton).balanceOf(user1);

        WstonSwapPool(wstonSwapPoolProxyAddress).removeLiquidity(user1Shares);

        uint256 user1wstonBalanceAfter = IERC20(wston).balanceOf(user1);
        uint256 user1tonBalanceAfter = IERC20(ton).balanceOf(user1);

        assert(user1wstonBalanceAfter == user1wstonBalanceBefore + wstonReserve);
        assert(user1tonBalanceAfter == user1tonBalanceBefore + tonReserve);
        vm.stopPrank;
    }

    function testMultipleLiquidityProviders() public {
        
        // user1 addsliquidity for 100 TON and 100 WSTON
        vm.startPrank(user1);

        uint256 user1tonAmount = 100*10**18;
        uint256 user1wstonAmount = 100*10**27;
        IERC20(ton).approve(wstonSwapPoolProxyAddress, user1tonAmount);
        IERC20(wston).approve(wstonSwapPoolProxyAddress, user1wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).addLiquidity(user1tonAmount, user1wstonAmount);

        vm.stopPrank;

        //user2 adds liquidity for 500 TON and 250 WSTON
        vm.startPrank(user2);
        uint256 user2tonAmount = 500*10**18;
        uint256 user2wstonAmount = 250*10**27;
        IERC20(ton).approve(wstonSwapPoolProxyAddress, user2tonAmount);
        IERC20(wston).approve(wstonSwapPoolProxyAddress, user2wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).addLiquidity(user2tonAmount, user2wstonAmount);
        vm.stopPrank;

        // user swaps 20 WSTON for TON
        vm.startPrank(user3);

        uint256 user3tonBalanceBefore = IERC20(ton).balanceOf(user3);

        uint256 wstonAmount = 20*10**27;
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swapWSTONforTON(wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();
        vm.stopPrank();

        uint256 user3tonBalanceAfter = IERC20(ton).balanceOf(user3);

        uint256 tonAmount = ((wstonAmount * 10**27) / 10**27) / (10**9);
        uint256 tonFees = (tonAmount * 3) / 1000; // 0.3%
        uint256 tonAmountTransferred = tonAmount - tonFees;

        // ensuring user2 received his TON
        assert(user3tonBalanceAfter == user3tonBalanceBefore + tonAmountTransferred);

        vm.stopPrank();

        uint256 user1Shares = WstonSwapPool(wstonSwapPoolProxyAddress).getLpShares(user1);
        uint256 totalShares = WstonSwapPool(wstonSwapPoolProxyAddress).getTotalShares();
        uint256 tonReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getTonReserve();
        uint256 wstonReserve = WstonSwapPool(wstonSwapPoolProxyAddress).getWstonReserve();

        vm.startPrank(user1);
        uint256 user1wstonBalanceBefore = IERC20(wston).balanceOf(user1);
        uint256 user1tonBalanceBefore = IERC20(ton).balanceOf(user1);

        // user 1 removes half of its shares => 100000000000000000000
        WstonSwapPool(wstonSwapPoolProxyAddress).removeLiquidity(user1Shares / 2);

        tonAmountTransferred = ((user1Shares/2) * tonReserve) / totalShares;
        uint256 wstonAmountTransferred = ((user1Shares/2) * wstonReserve) / totalShares;

        uint256 user1wstonBalanceAfter = IERC20(wston).balanceOf(user1);
        uint256 user1tonBalanceAfter = IERC20(ton).balanceOf(user1);

        assert(user1wstonBalanceAfter == user1wstonBalanceBefore + wstonAmountTransferred);
        assert(user1tonBalanceAfter == user1tonBalanceBefore + tonAmountTransferred);

        vm.stopPrank();

    }

    function testSwapTONforWSTONifNotTreasury() public {
        testAddLiquidity();
        //user1 attempts to swap
        vm.startPrank(user1);
        uint256 tonAmount = 50*10**18;
        IERC20(ton).approve(wstonSwapPoolProxyAddress, tonAmount);

        vm.expectRevert("function callable from treasury contract only");
        WstonSwapPool(wstonSwapPoolProxyAddress).swapTONforWSTON(tonAmount);

        vm.stopPrank();
    }

    function testSwapTONforWSTONFromTreasury() public {
        testAddLiquidity();
        vm.startPrank(owner);
        uint256 treasurywstonBalanceBefore = IERC20(wston).balanceOf(treasuryProxyAddress);
        uint256 tonAmount = 50*10**18;
        Treasury(treasuryProxyAddress).tonApproveWstonSwapPool(tonAmount);

        Treasury(treasuryProxyAddress).swapTONforWSTON(tonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();

        uint256 wstonAmountSwapped = tonAmount * (10**9);
        uint256 wstonFees = (wstonAmountSwapped * 3) / 1000;
        
        //ensuring treasury received the WSTON swapped
        uint256 treasurywstonBalanceAfter = IERC20(wston).balanceOf(treasuryProxyAddress);

        assert(treasurywstonBalanceAfter == treasurywstonBalanceBefore + wstonAmountSwapped - wstonFees);

        vm.stopPrank();
    }

    function testSwapWSTONforTONWithUpdatedStakingIndex() public {
        testAddLiquidity();
        uint256 user1tonBalanceBefore = IERC20(ton).balanceOf(user1);

        vm.startPrank(owner);
        uint256 newStakingIndex = 12*10**26; // 1.2 
        WstonSwapPool(wstonSwapPoolProxyAddress).updateStakingIndex(newStakingIndex);
        vm.stopPrank();

        vm.startPrank(user2);
         uint256 user2tonBalanceBefore = IERC20(ton).balanceOf(user2);

        //user wants to swap 50 WSTON for TON
        uint256 wstonAmount = 50*10**27;
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swapWSTONforTON(wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();
        vm.stopPrank();

        uint256 user1tonBalanceAfter = IERC20(ton).balanceOf(user1);
        uint256 user2tonBalanceAfter = IERC20(ton).balanceOf(user2);

        uint256 tonAmount = ((wstonAmount * newStakingIndex) / 10**27) / (10**9);
        uint256 tonFees = (tonAmount * feeRate) / 10000; // 0.3%
        tonAmount -= tonFees;

        // ensuring user2 received his TON
        assert(user2tonBalanceAfter == user2tonBalanceBefore + tonAmount);

        // ensureing user1 received associated fees in TON
        assert(user1tonBalanceAfter == user1tonBalanceBefore + tonFees);

    }

    function testRemoveLiquidityIfTONReserveIsEmpty() public {
        testAddLiquidity();

        uint256 user2tonBalanceBefore = IERC20(ton).balanceOf(user2);
        uint256 user1tonBalanceBefore = IERC20(ton).balanceOf(user1);
        uint256 user1wstonBalanceBefore = IERC20(wston).balanceOf(user1);


        vm.startPrank(user2);
        //user wants to swap 100 WSTON for TON
        uint256 wstonAmount = 100*10**27;
        IERC20(wston).approve(wstonSwapPoolProxyAddress, wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).swapWSTONforTON(wstonAmount);
        WstonSwapPool(wstonSwapPoolProxyAddress).distributeFees();
        vm.stopPrank();

        // TON reserve = 0
        // WSTON reserve = 200

        uint256 user2tonBalanceAfter = IERC20(ton).balanceOf(user2);

        uint256 user1tonBalanceAfter = IERC20(ton).balanceOf(user1);

        vm.startPrank(user1);
        uint256 user1Shares = WstonSwapPool(wstonSwapPoolProxyAddress).getLpShares(user1);
        uint256 wstonReserveBeforeRemovingLiquidity = WstonSwapPool(wstonSwapPoolProxyAddress).getWstonReserve();

        WstonSwapPool(wstonSwapPoolProxyAddress).removeLiquidity(user1Shares);

        vm.stopPrank();

        uint256 user1wstonBalanceAfter = IERC20(wston).balanceOf(user1);

        uint256 tonAmount = ((wstonAmount * 10**27) / 10**27) / (10**9);
        uint256 tonFees = (tonAmount * feeRate) / 10000; // 0.3%
        uint256 tonAmountTransferred = tonAmount - tonFees;

        assert(user2tonBalanceAfter == user2tonBalanceBefore + tonAmountTransferred); 
        assert(user1tonBalanceAfter == user1tonBalanceBefore + tonFees); 
        assert(user1wstonBalanceAfter == user1wstonBalanceBefore + wstonReserveBeforeRemovingLiquidity);
    }

}