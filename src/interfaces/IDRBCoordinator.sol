// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title Commit-Recover
 * @author Justin g
 * @notice This contract is for generating random number
 *    1. Finished: round not Started | recover the random number
 *    2. Commit: participants commit their value
 */
interface IDRBCoordinator {
    struct RandomWordsRequest {
        uint16 security;
        uint16 mode;
        uint32 callbackGasLimit;
    }

    function requestRandomWordDirectFunding(
        RandomWordsRequest calldata _request
    ) external payable returns (uint256);

    function calculateDirectFundingPrice(
        RandomWordsRequest calldata _request
    ) external view returns (uint256);

    function fulfillRandomness(uint256 requestId) external;
}