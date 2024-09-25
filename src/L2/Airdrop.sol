// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../proxy/ProxyStorage.sol";
import {AirdropStorage} from "./AirdropStorage.sol";
import {AuthControl} from "../common/AuthControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IGemFactory.sol";

interface ITreasury {
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external;
}

contract Airdrop is AirdropStorage, ProxyStorage, AuthControl, ReentrancyGuard {
    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor(address _treasury, address _gemFactory) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        treasury = _treasury;
        gemFactory = _gemFactory;
    }
    /**
     * @notice this function must be called by the owner or an admin to assign a list of tokens to a particular user. 
     * This user will then be able to call claimAirdrop. The owner or the admins can call assignGemForAirdrop multiple times
     * without clearing the previous list of tokens.
     * @param _tokenIds list of tokens
     * @param _to  user that must benefit from the airdrop
     */
    function assignGemForAirdrop(uint256[] memory _tokenIds, address _to) external onlyOwnerOrAdmin returns(bool) {
        uint256[] storage existingTokens = tokensEligible[_to];
        uint256[] memory uniqueTokenIds = new uint256[](_tokenIds.length);
        uint256 uniqueCount = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            bool isDuplicate = false;

            // Check for duplicates within _tokenIds
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTokenIds[j] == tokenId) {
                    isDuplicate = true;
                    break;
                }
            }

            // Check for duplicates in existing tokensEligible
            if (!isDuplicate) {
                for (uint256 k = 0; k < existingTokens.length; k++) {
                    if (existingTokens[k] == tokenId) {
                        isDuplicate = true;
                        break;
                    }
                }
            }

            require(IGemFactory(gemFactory).ownerOf(tokenId) == treasury, "Token not owned by the treasury");
            require(IGemFactory(gemFactory).isTokenLocked(tokenId) == false, "Token is not available");

            uniqueTokenIds[uniqueCount] = tokenId;
            uniqueCount++;
        }

        // Resize the array to fit the number of unique tokens
        uint256[] memory finalTokenIds = new uint256[](uniqueCount);
        for (uint256 j = 0; j < uniqueCount; j++) {
            finalTokenIds[j] = uniqueTokenIds[j];
        }

        // Assign unique tokens to the user
        tokensEligible[_to] = finalTokenIds;
        userClaimed[_to] = false;

        emit TokensAssigned(finalTokenIds, _to);
        return true;
    }


    /**
     * @notice claimAirdrop function transfers ownership of each GEM assigned to msg.sender.
     */
    function claimAirdrop() external whenNotPaused nonReentrant {
        require(userClaimed[msg.sender] == false, "user already claimed");
        uint256[] memory _tokenIds = tokensEligible[msg.sender];
        require(_tokenIds.length > 0, "user is not eligible for any token");

        userClaimed[msg.sender] = true;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ITreasury(treasury).transferTreasuryGEMto(msg.sender, _tokenIds[i]);
        }

        // Clear the array after claiming
        delete tokensEligible[msg.sender];

        emit TokensClaimed(_tokenIds, msg.sender);
    }

}