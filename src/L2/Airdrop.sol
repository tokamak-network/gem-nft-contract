// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../proxy/ProxyStorage.sol";
import {AirdropStorage} from "./AirdropStorage.sol";
import {AuthControl} from "../common/AuthControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IGemFactory.sol";

interface ITreasury {
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external;
}

/**
 * @title Airdrop Contract
 * @author TOKAMAK OPAL TEAM
 * @notice This contract manages the airdrop of GEM tokens to users. 
 * @dev Inherits from ProxyStorage, AirdropStorage, AuthControl, and ReentrancyGuard.
 * @dev only admins are allowed to assign GEMs to users
 * @dev user claim gems by their own
 */
contract Airdrop is ProxyStorage, AirdropStorage, AuthControl, ReentrancyGuard {

    /**
     * @notice Modifier to ensure the contract is not paused.
     */

    modifier whenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }

    /**
     * @notice Modifier to ensure the contract is paused.
     */
    modifier whenPaused() {
        if (!paused) {
            revert ContractNotPaused();
        }
        _;
    }
    /**
     * @notice Pauses the contract, preventing certain actions.
     * @dev Can only be called by the owner when the contract is not paused.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @notice Unpauses the contract, allowing actions to be performed.
     * @dev Can only be called by the owner when the contract is paused.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @notice Initializes the contract with the treasury and gem factory addresses.
     * @param _treasury The address of the treasury contract.
     * @param _gemFactory The address of the gem factory contract.
     * @dev Can only be called once. Grants the default admin role to the caller.
     */
    function initialize(address _treasury, address _gemFactory) external {
        if(initialized) {
            revert AlreadyInitialized();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        treasury = _treasury;
        gemFactory = _gemFactory;
        initialized = true;  
    }


    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------


        /**
     * @notice Assigns a list of GEM tokens to a user for airdrop.
     * @param _tokenIds The list of GEM token IDs to assign.
     * @param _to The address of the user to receive the airdrop.
     * @return A boolean indicating success.
     * @dev Can only be called by the owner or an admin. Ensures tokens are unique and owned by the treasury.
     */
    function assignGemForAirdrop(uint256[] memory _tokenIds, address _to) external onlyOwnerOrAdmin returns (bool) {
        uint256[] storage existingTokens = tokensEligible[_to];
        uint256 tokenIdLength = _tokenIds.length;
              uint256 existingTokensLength = existingTokens.length;

        for (uint256 i = 0; i < tokenIdLength; ++i) {
            uint256 tokenId = _tokenIds[i];

            for (uint256 k = 0; k < existingTokensLength; ++k) {
                if (existingTokens[k] == tokenId) {
                    continue;
                }
            }
            // safety checks to ensure the gem is owned by the treasury and it is not locked
            if (IGemFactory(gemFactory).ownerOf(tokenId) != treasury) {
                revert TokenNotOwnedByTreasury();
            }
            if (IGemFactory(gemFactory).isTokenLocked(tokenId)) {
                revert TokenNotAvailable();
            }

            // Lock the token so that it cannot be sent to another user through the mining or random pack process
            IGemFactory(gemFactory).setIsLocked(tokenId, true);
            existingTokens.push(tokenId);
        }

        userClaimed[_to] = false;

        // Add user to the mapping of users with eligible tokens if not already present
        if (!userHasEligibleTokens[_to]) {
            userHasEligibleTokens[_to] = true;
            usersWithEligibleTokens.push(_to);
        }

        emit TokensAssigned(existingTokens, _to);
        return true;
    }

    /**
     * @notice Claims the airdrop of GEM tokens assigned to the caller.
     * @dev Transfers ownership of each GEM token to the caller. Can only be called when not paused.
     */
    function claimAirdrop() external whenNotPaused nonReentrant {

        if(userClaimed[msg.sender] == true) {
            revert UserAlreadyClaimedCurrentAirdrop();
        }
        uint256[] memory _tokenIds = tokensEligible[msg.sender];
        uint256 tokenIdsLength = _tokenIds.length;
        if(tokenIdsLength == 0) {
            revert UserNotEligible();
        }

        // mappings reset
        userClaimed[msg.sender] = true;
        delete tokensEligible[msg.sender];
        userHasEligibleTokens[msg.sender] = false;

        for (uint256 i = 0; i < tokenIdsLength; ++i) {
            // This condition is made in case there was duplicates in the list so it does not revert
            if (IGemFactory(gemFactory).ownerOf(_tokenIds[i]) == treasury) {
                IGemFactory(gemFactory).setIsLocked(_tokenIds[i], false);
                ITreasury(treasury).transferTreasuryGEMto(msg.sender, _tokenIds[i]);
            }
        }

        emit TokensClaimed(_tokenIds, msg.sender);
    }

    /**
     * @notice Clears all tokens eligible for airdrop for all users.
     * @dev Can only be called by the owner or an admin.
     * @return A boolean indicating success.
     */
    function clearEligibleTokensList() external onlyOwnerOrAdmin returns(bool) {
      uint256 usersWithEligibleTokensLength= usersWithEligibleTokens.length;
        // make the function revert if there is no eligible tokens
        if(usersWithEligibleTokensLength == 0) {
            revert NoEligibleUsers();
        }
        
        // deleting tokenEligible Mapping for each userthat was assigned with airdrop tokens
        for (uint256 i = 0; i < usersWithEligibleTokensLength; ++i) {
            address user = usersWithEligibleTokens[i];
            delete tokensEligible[user];
            userClaimed[user] = false;
            userHasEligibleTokens[user] = false;
        }

        // Clear the list of users with eligible tokens
        delete usersWithEligibleTokens;

        emit EligibleTokenListCleared();
        return true;
    }

    //---------------------------------------------------------------------------------------
    //------------------------------VIEW FUNCTIONS/STORAGE GETTERS---------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Returns the list of GEM tokens eligible for airdrop for a given address.
     * @param _address The address to query for eligible tokens.
     * @return An array of token IDs eligible for airdrop.
     */
    function getTokensEligible(address _address) public view returns (uint256[] memory) {
        return tokensEligible[_address];
    }

    /**
     * @notice Returns whether a user has claimed their airdrop.
     * @param _user The address of the user.
     * @return A boolean indicating if the user has claimed their airdrop.
     */
    function getUserClaimed(address _user) external view returns (bool) {
        return userClaimed[_user];
    }

    /**
     * @notice Returns the address of the treasury.
     * @return The address of the treasury.
     */
    function getTreasury() external view returns (address) {
        return treasury;
    }

    /**
     * @notice Returns the address of the gem factory.
     * @return The address of the gem factory.
     */
    function getGemFactory() external view returns (address) {
        return gemFactory;
    }

    /**
     * @notice Returns the list of users with eligible tokens.
     * @return An array of addresses of users with eligible tokens.
     */
    function getUsersWithEligibleTokens() external view returns (address[] memory) {
        return usersWithEligibleTokens;
    }

    /**
     * @notice Returns whether the contract is paused.
     * @return A boolean indicating if the contract is paused.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @notice Returns whether the contract has been initialized.
     * @return A boolean indicating if the contract has been initialized.
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }

    /**
     * @notice Returns whether a user has eligible tokens.
     * @param _user The address of the user.
     * @return A boolean indicating if the user has eligible tokens.
     */
    function hasEligibleTokens(address _user) external view returns (bool) {
        return userHasEligibleTokens[_user];
    }

}