// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract WSTONSwapPool is Ownable {
    constructor() Ownable(msg.sender) {

    }
    /**
     * @notice Add liquidity to the WSTON/TON pool. Receive liquidity token to materialize shares in the pool
     * @param _wstonAmount amount of WSTON to deposit
     * @param _stakingIndex staking index of the associated wstonAmount to be deposited
     * @param _tonAmount amount of TON to deposit
     */
    function addLiquidity(uint256 _wstonAmount, uint256 _stakingIndex, uint256 _tonAmount) external {

    }

    function removeLiquidity(uint256 _wstonAmount, uint256 _stakingIndex, uint256 _tonAmount) external {

    }

    function swapTONforWSTON(uint256 _amount) external {

    }

    function swapWSTONforTON(uint256 _amount, uint256 _stakingIndex) external {

    }
}