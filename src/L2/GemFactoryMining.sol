// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../proxy/ProxyStorage.sol";
import "./GemFactoryStorage.sol";
import { MiningLibrary } from "../libraries/MiningLibrary.sol";
import {DRBConsumerBase} from "./Randomness/DRBConsumerBase.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
}

/**
 * @title GemFactoryMining
 * @author TOKAMAK OPAL TEAM
 * @notice additionnal implementation of GemFactory (should be set as an implementation within GemFactoryProxy). 
 * @dev this additionnal implementation manages the mining feature 
 * @dev Since this contract have a proxy index different from 0, users can not interact with these functions directly from the explorer. 
 * However, please note that this contract is deployed and operational
 */
contract GemFactoryMining is ProxyStorage, GemFactoryStorage, ERC721URIStorageUpgradeable, ReentrancyGuard, DRBConsumerBase {
    using MiningLibrary for GemFactoryStorage.Gem[];
    bool GFMiningInitialized = false;

    event DRBCoordiantorInitialized(address coordinator);
    error DRBAlreadyInitialized();

    /**
     * @notice Modifier to ensure the contract is not paused.
     */
    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    function DRBInitialize(address _coordinator) external {
        if(GFMiningInitialized) {
            revert DRBAlreadyInitialized();
        }
        __DRBConsumerBase_init(_coordinator);
        emit DRBCoordiantorInitialized(_coordinator);
        GFMiningInitialized = true;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice triggers the mining process of a gem by the function caller
     * @param _tokenId Id of the token to be mined.
     * @return true if the gem user started mining the gem
     * @dev the Gem must be Rare or above
     * @dev the cooldown period must have elapsed
     * @dev the Gem must not be locked. Therefore, it must not be listed on the marketplace 
     * @dev There must be more than 1 mining try left.
     */
    function startMiningGEM(uint256 _tokenId) external whenNotPaused returns (bool) {
        // Ensure the caller's address is not zero
        if (msg.sender == address(0)) {
            revert AddressZero();
        }
        // Ensure the caller is the owner of the GEM
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        // Ensure the cooldown period for the GEM has elapsed
        if (Gems[_tokenId].gemCooldownDueDate > block.timestamp) {
            revert CooldownPeriodNotElapsed();
        }
        // Ensure the GEM is not currently locked
        if (Gems[_tokenId].isLocked) {
            revert GemIsLocked();
        }
        // Ensure the GEM's rarity is not COMMON, as COMMON gems cannot be mined
        if (Gems[_tokenId].rarity == Rarity.COMMON) {
            revert WrongRarity();
        }
        // Ensure there are mining attempts left for the GEM
        if (Gems[_tokenId].miningTry == 0) {
            revert NoMiningTryLeft();
        }

        // Modify storage variables to start the mining process
        Gems.startMining(userMiningToken, userMiningStartTime, numberMiningGemsByRarity, msg.sender, _tokenId);

        // Emit an event indicating that mining has started
        emit GemMiningStarted(_tokenId, msg.sender, block.timestamp, Gems[_tokenId].miningTry);
        return true;
    }

    /**
     * @notice function that cancels the mining process. note that the mining attempt spent is not recovered
     * @param _tokenId the id of the token that is mining
     * @dev the user must be the owner of the token
     * @dev the user must be mining this token.
     * @dev the user must not have already called pickMinedGem function
     */
    function cancelMining(uint256 _tokenId) external whenNotPaused returns (bool) {
        // Ensure the caller is the owner of the GEM
        if (GEMIndexToOwner[_tokenId] != msg.sender) {
            revert NotGemOwner();
        }
        // Ensure the GEM is currently locked, indicating it is in the mining process
        if (Gems[_tokenId].isLocked != true) {
            revert GemIsNotLocked();
        }
        // Ensure the GEM is currently being mined by the user
        if (userMiningToken[msg.sender][_tokenId] != true) {
            revert NotMining();
        }
        // Ensure the GEM has not already been picked (randomness request not initiated)
        if (Gems[_tokenId].randomRequestId != 0) {
            revert GemAlreadyPicked();
        }

        // Modify the storage variables associated with the mining process to cancel it
        Gems.cancelMining(userMiningToken, userMiningStartTime, numberMiningGemsByRarity, msg.sender, _tokenId);

        // Emit an event indicating that mining has been canceled
        emit MiningCancelled(_tokenId, msg.sender, block.timestamp);
        return true;
    }

    /**
     * @notice Picks a mined gem after the mining period has elapsed.
     * @param _tokenId ID of the token to pick.
     * @return requestId The request ID for randomness.
     * @dev user pays msg.value and get back the excess ETH that is not spent on gas by the node
     */
    function pickMinedGEM(uint256 _tokenId) external payable whenNotPaused nonReentrant returns (uint256) {
        // Ensure the caller is the owner of the GEM
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        // Ensure the mining period has elapsed
        if (block.timestamp < userMiningStartTime[msg.sender][_tokenId] + getMiningPeriodBasedOnRarity(Gems[_tokenId].rarity)) {
            revert MiningPeriodNotElapsed();
        }
        // Ensure the GEM is currently locked
        if (Gems[_tokenId].isLocked == false) {
            revert GemIsNotLocked();
        }
        // Ensure the GEM is currently being mined
        if (userMiningToken[ownerOf(_tokenId)][_tokenId] != true) {
            revert NotMining();
        }

        // Request randomness from the consumer with default parameters
        (uint256 directFundingCost, uint256 requestId) = requestRandomness(0, 0, callbackGasLimit);
        // Store the request ID in the GEM's data
        Gems[_tokenId].randomRequestId = requestId;

        // Update the request mapping with details of the request
        s_requests[requestId].tokenId = _tokenId;
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            // Increment the request count
            requestCount++;
        }

        // Refund excess ETH to the user if they overpaid
        if (msg.value > directFundingCost) {
            // Refund excess ETH to the user if they overpaid
            uint256 ethToRefund = msg.value - directFundingCost;
            (bool success, ) = msg.sender.call{value: ethToRefund}("");
            if (!success) {
                revert FailedToSendEthBack();
            }
            // Emit an event for the ETH refund
            emit EthSentBack(ethToRefund);
        }

        // Emit an event for the random GEM request
        emit RandomGemRequested(_tokenId, Gems[_tokenId].randomRequestId);
        return requestId;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------PRIVATE/INERNAL FUNCTIONS------------------------------------
    //---------------------------------------------------------------------------------------

     /**
     * @notice Fulfills a random number request and processes GEM mining.
     * @dev Implements the abstract function from DRBConsumerBase.
     * @dev Counts the total of eligible gems for mining
     * @dev Performs randomNumber % gemCount to get a number between 1 and gemCount
     * @dev Unlocks the initial Gem, reset the cooldown period and the randomRequestId
     * @dev Transfers the picked Gem from the treasury to the user
     * @param requestId The ID of the request.
     * @param randomNumber The random number generated.
     */
    function fulfillRandomWords(uint256 requestId, uint256 randomNumber) internal override {
        // Check if the request was made
        if(!s_requests[requestId].requested) {
            revert RequestNotMade();
        }
        // Mark the request as fulfilled and store the random number
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = randomNumber;
        uint256 _tokenId = s_requests[requestId].tokenId;

        // Retrieve the quadrants of the GEM
        uint8[4] memory quadrants = Gems[s_requests[requestId].tokenId].quadrants;
        
        // Count the number of GEMs by quadrant and emit an event
        (uint256 gemCount, uint256[] memory tokenIds) = countGemsByQuadrant(quadrants[0], quadrants[1], quadrants[2], quadrants[3]);
        emit CountGemsByQuadrant(gemCount, tokenIds);

        if(gemCount > 0) {
            // Select a GEM based on the random number
            uint256 modNbGemsAvailable = (randomNumber % gemCount);
            s_requests[requestId].chosenTokenId = tokenIds[modNbGemsAvailable];

            // we set mining try of the mined gem to 0 => mined gems can't mine other gems
            Gems[s_requests[requestId].chosenTokenId].miningTry = 0;

            // Transfer the GEM to the requester
            require(ITreasury(treasury).transferTreasuryGEMto(s_requests[requestId].requester, s_requests[requestId].chosenTokenId), "failed to transfer token");
            
            // fetching the mined gem's cooldown period
            uint256 minedGemCooldownDueDate = Gems[s_requests[requestId].chosenTokenId].gemCooldownDueDate;
            uint256 chosenTokenId = s_requests[requestId].chosenTokenId;
            uint256 initialGemCooldownDueDate = block.timestamp + _getCooldownPeriod(Gems[s_requests[requestId].tokenId].rarity);

            // Emit an event for the GEM mining claim
            emit GemMiningClaimed(_tokenId, chosenTokenId, minedGemCooldownDueDate, initialGemCooldownDueDate, s_requests[requestId].requester);
        } else {
            // No GEM available, set chosenTokenId to 0 and emit an event
            s_requests[requestId].chosenTokenId = 0;
            uint256 initialGemCooldownDueDate = block.timestamp + _getCooldownPeriod(Gems[s_requests[requestId].tokenId].rarity);
            emit NoGemAvailable(_tokenId, initialGemCooldownDueDate, s_requests[requestId].requester);
        }
        
        // reset storage variable of the initial GEM
        Gems[_tokenId].isLocked = false;
        Gems[_tokenId].randomRequestId = 0;
        Gems[_tokenId].gemCooldownDueDate = block.timestamp + _getCooldownPeriod(Gems[s_requests[requestId].tokenId].rarity);

        // update mining tries
        numberMiningGemsByRarity[Gems[_tokenId].rarity]--;

        // update user mining storage
        delete userMiningToken[ownerOf(_tokenId)][_tokenId];
        delete userMiningStartTime[ownerOf(_tokenId)][_tokenId];
    }

    /**
     * @notice Counts the number of Gems from the treasury with quadrants less than the specified values.
     * @param quadrant1 The first quadrant value to compare.
     * @param quadrant2 The second quadrant value to compare.
     * @param quadrant3 The third quadrant value to compare.
     * @param quadrant4 The fourth quadrant value to compare.
     * @return The count of Gems and an array of their token IDs.
     */
    function countGemsByQuadrant(uint8 quadrant1, uint8 quadrant2, uint8 quadrant3, uint8 quadrant4) internal view returns (uint256, uint256[] memory) {
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](Gems.length);
        uint256 index = 0;
        uint8 sumOfQuadrants = quadrant1 + quadrant2 + quadrant3+ quadrant4;
        uint256 gemsLength = Gems.length;
        // Iterate through the Gems to count those with quadrants less than the specified sum
        for (uint256 i = 0; i < gemsLength; ++i) {
            uint8 GemSumOfQuadrants = Gems[i].quadrants[0] + Gems[i].quadrants[1] + Gems[i].quadrants[2] + Gems[i].quadrants[3];
            if (GemSumOfQuadrants < sumOfQuadrants && 
                GEMIndexToOwner[i] == treasury &&
                !Gems[i].isLocked
            ) {
                tokenIds[index] = Gems[i].tokenId;
                unchecked{
                    index++;
                    count++;
                } 
            }
        }
        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; ++j) {
            result[j] = tokenIds[j];
        }

        return (count, result);
    }


    /**
     * @notice Gets the cooldown period for a GEM based on its rarity.
     * @param rarity The rarity of the GEM.
     * @return The cooldown period in seconds.
     */
    function _getCooldownPeriod(Rarity rarity) internal view returns (uint256) {
        // Return the cooldown period based on the rarity
        if (rarity == Rarity.COMMON) return 0;
        if (rarity == Rarity.RARE) return RareGemsCooldownPeriod;
        if (rarity == Rarity.UNIQUE) return UniqueGemsCooldownPeriod;
        if (rarity == Rarity.EPIC) return EpicGemsCooldownPeriod;
        if (rarity == Rarity.LEGENDARY) return LegendaryGemsCooldownPeriod;
        if (rarity == Rarity.MYTHIC) return MythicGemsCooldownPeriod;
        // Revert if the rarity is invalid
        revert("Invalid rarity");
    }

    /**
     * @notice Retrieves the mining period of a GEM based on its rarity.
     * @param _rarity The rarity of the GEM.
     * @return value The mining period associated with the specified rarity.
     */
    function getMiningPeriodBasedOnRarity(Rarity _rarity) internal view returns (uint256 value) {
        // Determine the value based on the rarity of the GEM
        if (_rarity == Rarity.RARE) {
            value = RareGemsMiningPeriod;
        } else if (_rarity == Rarity.UNIQUE) {
            value = UniqueGemsMiningPeriod;
        } else if (_rarity == Rarity.EPIC) {
            value = EpicGemsMiningPeriod;
        } else if (_rarity == Rarity.LEGENDARY) {
            value = LegendaryGemsMiningPeriod;
        } else if (_rarity == Rarity.MYTHIC) {
            value = MythicGemsMiningPeriod;
        } else {
            // Revert if the rarity is not recognized
            revert("wrong rarity");
        }
    }


}
