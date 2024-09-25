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
     * This user will then be able to call claimAirdrop
     * @param _tokenIds list of tokens
     * @param _to  user that must benefit from the airdrop
     */
    function assignGemForAirdrop(uint256[] memory _tokenIds, address _to) external onlyOwnerOrAdmin returns(bool) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(IGemFactory(gemFactory).ownerOf(_tokenIds[i]) == treasury, "token not owned by the treasury");
            require(IGemFactory(gemFactory).isTokenLocked(_tokenIds[i]) == false, "token is not available");
        }
        tokensEligible[_to] = _tokenIds;
        userClaimed[_to] = false;

        emit TokensAssigned(_tokenIds, _to);
        return true;
    }

    function claimAirdrop() external whenNotPaused nonReentrant {
        require(userClaimed[msg.sender] == false, "user already claimed");
        uint256[] memory _tokenIds = tokensEligible[msg.sender];
        require(_tokenIds.length > 0, "user is not eligible for any token");

        userClaimed[msg.sender] = true;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ITreasury(treasury).transferTreasuryGEMto(msg.sender, _tokenIds[i]);
        }
        emit TokensClaimed(_tokenIds, msg.sender);
    }

}