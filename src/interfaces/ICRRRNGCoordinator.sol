// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title Commit-Recover
 * @author Justin g
 * @notice This contract is for generating random number
 *    1. Finished: round not Started | recover the random number
 *    2. Commit: participants commit their value
 */
interface ICRRRNGCoordinator {
    function requestRandomWordDirectFunding(
        uint32 _callbackGasLimit
    ) external payable returns (uint256);

    function calculateDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256);
}
