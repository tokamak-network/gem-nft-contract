// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./L2BaseTest.sol";
import { WstonSwapPoolV2 } from "../../src/L2/WstonSwapPoolV2.sol";
import { WstonSwapPoolStorageV2 } from "../../src/L2/WstonSwapPoolStorageV2.sol";
import { WstonSwapPoolProxyV2 } from "../../src/L2/WstonSwapPoolProxyV2.sol";

contract WstonSwap is L2BaseTest {

    WstonSwapPoolV2 wstonSwapPoolV2;
    WstonSwapPoolProxyV2 wstonSwapPoolProxyV2;
    address wstonSwapPoolProxyV2Address;

    uint256 public constant INITIAL_STAKING_INDEX = 10**27;
    uint256 public constant DECIMALS = 10**27;

    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);

        wstonSwapPoolV2 = new WstonSwapPoolV2();
        wstonSwapPoolProxyV2 = new WstonSwapPoolProxyV2();
        wstonSwapPoolProxyV2.upgradeTo(address(wstonSwapPoolV2));
        wstonSwapPoolProxyV2Address = address(wstonSwapPoolProxyV2);
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).initialize(
            ton,
            wston,
            INITIAL_STAKING_INDEX,
            treasuryProxyAddress
        );

        Treasury(treasuryProxyAddress).setWstonSwapPool(wstonSwapPoolProxyV2Address);

        vm.stopPrank();

    }

    function testSetUp() public view {
        uint256 stakingIndex = WstonSwapPoolV2(wstonSwapPoolProxyV2Address).getStakingIndex();
        assert(stakingIndex == INITIAL_STAKING_INDEX);
    }

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
        IERC20(wston).approve(wstonSwapPoolProxyV2Address, wstonAmount);
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).swap(wstonAmount);
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
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).updateStakingIndex(newStakingIndex);
        vm.stopPrank();
        
        // user1 calls the swap function after approving
        vm.startPrank(user1);
        uint256 wstonAmount = 100 * 1e27;
        // approving the swapper to spend the amount
        IERC20(wston).approve(wstonSwapPoolProxyV2Address, wstonAmount);
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).swap(wstonAmount);
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
        IERC20(wston).approve(wstonSwapPoolProxyV2Address, wstonAmount);
        vm.expectRevert(WstonSwapPoolStorageV2.ContractTonBalanceOrAllowanceTooLow.selector);
        WstonSwapPoolV2(wstonSwapPoolProxyV2Address).swap(wstonAmount);
        vm.stopPrank();
    }
}