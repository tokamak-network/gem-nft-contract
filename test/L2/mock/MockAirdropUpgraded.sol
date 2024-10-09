// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../../../src/proxy/ProxyStorage.sol";
import {AirdropStorage} from "../../../src/L2/AirdropStorage.sol";
import {AuthControl} from "../../../src/common/AuthControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../../src/interfaces/IGemFactory.sol";

interface ITreasury {
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external;
}

contract MockAirdropUpgraded is ProxyStorage, AirdropStorage, AuthControl, ReentrancyGuard {
    
    // new storage
    uint256 public counter;


    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function initialize(address _treasury, address _gemFactory) external {
        require(!initialized, "already initialized"); 
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        treasury = _treasury;
        gemFactory = _gemFactory;
        initialized = true;  
    }


    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------


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
            for (uint256 j = 0; j < uniqueCount; ++j) {
                if (uniqueTokenIds[j] == tokenId) {
                    isDuplicate = true;
                    break;
                }
            }

            // Check for duplicates in existing tokensEligible
            if (!isDuplicate) {
                for (uint256 k = 0; k < existingTokens.length; ++k) {
                    if (existingTokens[k] == tokenId) {
                        isDuplicate = true;
                        break;
                    }
                }
            }

            if(IGemFactory(gemFactory).ownerOf(tokenId) != treasury) {
                revert TokenNotOwnedByTreasury();
            }
            if(IGemFactory(gemFactory).isTokenLocked(tokenId) == true) {
                revert TokenNotAvailable();
            }

            // we lock the token so that it cannot be sent to another user through the mining or random pack process
            IGemFactory(gemFactory).setIsLocked(tokenId, true);
            uniqueTokenIds[uniqueCount] = tokenId;
            uniqueCount++;
        }

        // Resize the array to fit the number of unique tokens
        uint256[] memory finalTokenIds = new uint256[](uniqueCount);
        for (uint256 j = 0; j < uniqueCount; ++j) {
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
        if(userClaimed[msg.sender] == true) {
            revert UserAlreadyClaimedCurrentAirdrop();
        }
        uint256[] memory _tokenIds = tokensEligible[msg.sender];
        if(_tokenIds.length == 0) {
            revert UserNotEligible();
        }

        userClaimed[msg.sender] = true;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            IGemFactory(gemFactory).setIsLocked(_tokenIds[i], false);
            ITreasury(treasury).transferTreasuryGEMto(msg.sender, _tokenIds[i]);
        }

        // Clear the array after claiming
        delete tokensEligible[msg.sender];

        emit TokensClaimed(_tokenIds, msg.sender);
    }

    //---------------------------------------------------------------------------------------
    //------------------------------VIEW FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    function getTokensEligible(address _address) public view returns (uint256[] memory) {
        return tokensEligible[_address];
    }

    function incrementCounter() external {
        counter++;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }

    function getTreasuryAddress() external view returns(address) {
        return treasury;
    }

    function getGemFactoryAddress() external view returns(address) {
        return gemFactory;
    }

}