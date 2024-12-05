// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../proxy/ProxyStorage.sol";
import "./GemFactoryStorage.sol";
import { ForgeLibrary } from "../libraries/ForgeLibrary.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @title GemFactoryForging
 * @author TOKAMAK OPAL TEAM
 * @notice additionnal implementation of GemFactory (should be set as an implementation within GemFactoryProxy). 
 * @dev this additionnal implementation mananges the forging feature.
 * @dev Since this contract have a proxy index different from 0, users can not interact with these functions directly from the explorer. 
 * However, please note that this contract is deployed and operational
 */
contract GemFactoryForging is ProxyStorage, GemFactoryStorage, ERC721URIStorageUpgradeable {

    /**
     * @notice Modifier to ensure the contract is not paused
     */
    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    using ForgeLibrary for GemFactoryStorage.Gem[];

     /**
     * @notice function that allow users to forge their gems. Gems must have the same rarity. 
     * Users can choose the color the forged gem will have if it respects specific conditions. 
     * old gems are burnt while the new forged gem is minted.
     * @param _tokenIds array of tokens to be forged. Must respect some length depending on the rarity chosen
     * @param _rarity to check if the rarity of each token selected is the same
     * @param _color color desired of the forged gem
     */
    function forgeTokens(
        uint256[] memory _tokenIds,
        Rarity _rarity,
        uint8[2] memory _color
    ) external whenNotPaused returns (uint256 newGemId) {

        // Define ForgeParams struct with predefined values for various GEM types
        ForgeLibrary.ForgeParams memory params = ForgeLibrary.ForgeParams({
            RareGemsValue: RareGemsValue,
            UniqueGemsValue: UniqueGemsValue,
            EpicGemsValue: EpicGemsValue,
            LegendaryGemsValue: LegendaryGemsValue,
            MythicGemsValue: MythicGemsValue,
            RareminingTry: RareminingTry,
            UniqueminingTry: UniqueminingTry,
            EpicminingTry: EpicminingTry,
            LegendaryminingTry: LegendaryminingTry,
            MythicminingTry: MythicminingTry,
            RareGemsCooldownPeriod: RareGemsCooldownPeriod,
            UniqueGemsCooldownPeriod: UniqueGemsCooldownPeriod,
            EpicGemsCooldownPeriod: EpicGemsCooldownPeriod,
            LegendaryGemsCooldownPeriod: LegendaryGemsCooldownPeriod,
            MythicGemsCooldownPeriod: MythicGemsCooldownPeriod
        });

        // Initialize variables for forged GEM properties
        uint8[4] memory forgedQuadrants;
        Rarity newRarity;
        uint256 forgedGemsCooldownDueDate;
        uint8 forgedGemsminingTry;
        uint256 forgedGemsValue;

        // Call the forgeTokens function from Gems contract
        (newGemId, forgedQuadrants, newRarity, forgedGemsValue, forgedGemsCooldownDueDate, forgedGemsminingTry) = Gems.forgeTokens(
            GEMIndexToOwner,
            ownershipTokenCount,
            msg.sender,
            _tokenIds,
            _rarity,
            _color,
            params
        );

        // Emit an event for the forged GEM
        emit GemForged(msg.sender, _tokenIds, newGemId, newRarity, forgedQuadrants, _color, forgedGemsValue);

        // Burn the old tokens
        burnTokens(msg.sender, _tokenIds);

        // Mint the new token
        _safeMint(msg.sender, newGemId);
        _setTokenURI(newGemId, ""); // Set empty URI for the new token

        // Emit another event for the created GEM
        emit Created(newGemId, newRarity, _color, forgedGemsminingTry, forgedGemsValue, forgedQuadrants, forgedGemsCooldownDueDate, "", msg.sender);

        return newGemId;
    }

        /**
     * @notice Burns tokens internally.
     * @param _from Address from which tokens are burned.
     * @param _tokenIds Array of token IDs to burn.
     */
    function burnTokens(address _from, uint256[] memory _tokenIds) internal {
        for(uint256 i = 0; i < _tokenIds.length; ++i) {
            // delete GEM from the Gems array and every other ownership/approve storage
            delete Gems[_tokenIds[i]];
            ownershipTokenCount[_from]--;
            delete GEMIndexToOwner[_tokenIds[i]];
            // ERC721 burn function
            _burn(_tokenIds[i]);
        }
    }
}
