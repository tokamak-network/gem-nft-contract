// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ReentrancyGuardTransient} from "./ReentrancyGuardTransient.sol";
import {OptimismL1Fees} from "./OptimismL1Fees.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DRBConsumerBase} from "../Randomness/DRBConsumerBase.sol";
import {IDRBCoordinator} from "../../interfaces/IDRBCoordinator.sol";

// 🧬 DRBCoordinatorMock, A mock for testing code that relies on DRBCoordinator
contract DRBCoordinatorMock is
    IDRBCoordinator,
    Ownable,
    ReentrancyGuardTransient,
    OptimismL1Fees
{
    struct ValuesAtRequestId {
        uint256 requestedTime;
        uint256 cost;
        address consumer;
    }

    struct RandomWordsFullfill {
        uint256 random;
        bool isFullfilled;
        bool isSent;
    }

    event RandomWordsRequested(uint256 requestId, uint256 requestedTime);
    event FulfillRandomness(uint256 requestId, bool success, address fulfiller);

    error InsufficientAmount();
    error NoRequestFound();
    error AlreadyFullfilled();

    uint256 private s_avgL2GasUsed;
    uint256 private s_premiumPercentage;
    uint256 private s_flatFee;
    uint256 private s_calldataSizeBytes;

    uint256 private s_nextId;
    mapping(uint256 requestId => RandomWordsRequest) private s_requestInfo;
    mapping(uint256 requestId => ValuesAtRequestId) private s_valuesAtRound;
    mapping(uint256 requestId => RandomWordsFullfill) private s_randomWordsFullfill;
    /// @dev 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    constructor(
        uint256 avgL2GasUsed,
        uint256 premiumPercentage,
        uint256 flatFee,
        uint256 calldataSizeBytes
    ) Ownable(msg.sender) {
        s_avgL2GasUsed = avgL2GasUsed;
        s_premiumPercentage = premiumPercentage;
        s_flatFee = flatFee;
        s_calldataSizeBytes = calldataSizeBytes;
    }

    function requestRandomWordDirectFunding(
        RandomWordsRequest calldata _request
    ) external payable nonReentrant returns (uint256 requestId) {
        uint256 cost = _calculateDirectFundingPrice(tx.gasprice, _request);
        require(msg.value >= cost);
        requestId = s_nextId++;
        s_requestInfo[requestId] = _request;
        s_valuesAtRound[requestId] = ValuesAtRequestId({
            requestedTime: block.timestamp,
            cost: cost,
            consumer: msg.sender
        });
        //requestId = s_nextId++;
        emit RandomWordsRequested(requestId, s_valuesAtRound[requestId].requestedTime);
    }

    function fulfillRandomness(uint256 requestId) external nonReentrant {
        // Check if the request exists
        require(s_valuesAtRound[requestId].requestedTime > 0, "No request found");

        // Check if the request has already been fulfilled
        require(!s_randomWordsFullfill[requestId].isFullfilled, "Already fulfilled");

        // Generate a random number
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    requestId,
                    block.timestamp
                )
            )
        );

        // Call the consumer contract
        bool success = _call(
            s_valuesAtRound[requestId].consumer,
            abi.encodeWithSelector(
                DRBConsumerBase.rawFulfillRandomWords.selector,
                requestId,
                random
            ),
            s_requestInfo[requestId].callbackGasLimit
        );

        // Update the state to mark the request as fulfilled
        s_randomWordsFullfill[requestId] = RandomWordsFullfill({
            random: random,
            isFullfilled: true,
            isSent: success
        });

        // Emit an event to log the fulfillment
        emit FulfillRandomness(requestId, success, msg.sender);
    }

    function calculateDirectFundingPrice(
        RandomWordsRequest calldata _request
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(tx.gasprice, _request);
    }

    function estimateDirectFundingPrice(
        uint256 gasPrice,
        RandomWordsRequest calldata _request
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(gasPrice, _request);
    }

    function _calculateDirectFundingPrice(
        uint256 gasPrice,
        RandomWordsRequest calldata _request
    ) internal view returns (uint256) {
        return
            (((gasPrice * (_request.callbackGasLimit + s_avgL2GasUsed)) *
                (s_premiumPercentage + 100)) / 100) +
            s_flatFee +
            _getL1CostWeiForCalldataSize(s_calldataSizeBytes);
    }

    function _call(
        address target,
        bytes memory data,
        uint256 callbackGasLimit
    ) private returns (bool success) {
        assembly {
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available)
            // We want to ensure that we revert if gasAmount > 63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas. GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able to revert
            // if gasAmount > 63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                revert(0, 0)
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gas
            // we subtract g//64 because of EIP-150
            g := sub(g, div(g, 64))
            if iszero(gt(sub(g, div(g, 64)), callbackGasLimit)) {
                revert(0, 0)
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas, addr, value, argsOffset,argsLength,retOffset,retLength)
            success := call(
                callbackGasLimit,
                target,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
        return success;
    }
}