// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {ICRRRNGCoordinator} from "../interfaces/ICRRRNGCoordinator.sol";

/**
 * @notice Interface for contracts using VRF randomness
 * @dev USAGE
 *
 * @dev Consumer contracts must inherit from VRFConsumerBase, and can
 * @dev initialize Coordinator address in their constructor as
 */
abstract contract RNGConsumerBase {
    error OnlyCoordinatorCanFulfill(address have, address want);

    /// @dev The RNGCoordinator contract
    ICRRRNGCoordinator internal immutable i_rngCoordinator;

    /**
     * @param rngCoordinator The address of the RNGCoordinator contract
     */
    constructor(address rngCoordinator) {
        i_rngCoordinator = ICRRRNGCoordinator(rngCoordinator);
    }

    /**
     * @param _callbackGasLimit The amount of gas for processing of the callback request in your fulfillRandomWords()
     * @return requestId The ID of the request
     * @return requestPrice The calculated price of the request
     * @dev Request Randomness to the Coordinator
     * 1. Calculate the price of the request
     * 2. Request randomness from the Coordinator with sending the calculated price
     * 3. Return the requestId and requestPrice
     */
    function requestRandomness(uint32 _callbackGasLimit) internal returns (uint256, uint256) {
        uint256 requestPrice = i_rngCoordinator.calculateDirectFundingPrice(_callbackGasLimit);
        uint256 requestId = i_rngCoordinator.requestRandomWordDirectFunding{value: requestPrice}(
            _callbackGasLimit
        );
        return (requestId, requestPrice);
    }

    /**
     * @param _callbackGasLimit The amount of gas for processing of the callback request in your fulfillRandomWords()
     * @return The calculated price of the request
     */
    function getCalculatedDirectFundingPrice(
        uint32 _callbackGasLimit
    ) external view returns (uint256) {
        return i_rngCoordinator.calculateDirectFundingPrice(_callbackGasLimit);
    }

    /**
     * @param round The round of the randomness
     * @param hashedOmegaVal The hashed value of the random number
     * @dev Callback function for the Coordinator to call after the request is fulfilled.  Override this function in your contract
     */
    function fulfillRandomWords(uint256 round, uint256 hashedOmegaVal) internal virtual;

    /**
     * @param round The round of the randomness
     * @param hashedOmegaVal The hashed value of the random number
     * @dev Callback function for the Coordinator to call after the request is fulfilled. This function is called by the Coordinator
     */
    function rawFulfillRandomWords(uint256 round, uint256 hashedOmegaVal) external {
        if (msg.sender != address(i_rngCoordinator)) {
            revert OnlyCoordinatorCanFulfill(msg.sender, address(i_rngCoordinator));
        }
        fulfillRandomWords(round, hashedOmegaVal);
    }
}
