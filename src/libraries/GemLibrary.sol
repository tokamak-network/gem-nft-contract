// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../L2/GemFactoryStorage.sol";

library GemLibrary {
    /**
     * @notice Creates a new gem and assigns it to the specified owner.
     * @dev This function adds a new gem to the Gems array and updates the ownership mappings.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param rarity The rarity of the gem.
     * @param color The color attributes of the gem.
     * @param quadrants The quadrant attributes of the gem.
     * @param value The value of the gem.
     * @param gemCooldownPeriod The cooldown period for the gem.
     * @param miningTry The number of mining attempts for the gem.
     * @param tokenURI The URI for the gem's metadata.
     * @return The ID of the newly created gem.
     */
    function createGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        GemFactoryStorage.Rarity rarity,
        uint8[2] memory color,
        uint8[4] memory quadrants,
        uint256 value,
        uint256 gemCooldownPeriod,
        uint8 miningTry,
        string memory tokenURI
    ) internal returns (uint256) {
        GemFactoryStorage.Gem memory newGem = GemFactoryStorage.Gem({
            tokenId: 0,
            rarity: rarity,
            quadrants: quadrants,
            color: color,
            value: value,
            gemCooldownDueDate: gemCooldownPeriod,
            miningTry: miningTry,
            isLocked: false,
            tokenURI: tokenURI,
            randomRequestId: 0
        });

        Gems.push(newGem);
        uint256 newGemId = Gems.length - 1;
        Gems[newGemId].tokenId = newGemId;

        GEMIndexToOwner[newGemId] = owner;
        ownershipTokenCount[owner]++;

        return newGemId;
    }

    /**
     * @notice Burns a gem, removing it from the storage and updating ownership.
     * @dev This function deletes the gem from the Gems array and updates the ownership mappings.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param tokenId The ID of the gem to be burned.
     */
    function burnGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        uint256 tokenId
    ) internal {
        delete Gems[tokenId];
        ownershipTokenCount[owner]--;
        delete GEMIndexToOwner[tokenId];
    }

    /**
     * @notice Burns multiple gems, removing them from the storage and updating ownership.
     * @dev This function iterates over the provided token IDs and burns each gem.
     * @param Gems The storage array of gems.
     * @param GEMIndexToOwner Mapping from gem index to owner address.
     * @param ownershipTokenCount Mapping from owner address to the number of gems owned.
     * @param owner The address of the gem owner.
     * @param tokenIds An array of gem IDs to be burned.
     */
    function burnGems(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burnGem(Gems, GEMIndexToOwner, ownershipTokenCount, owner, tokenIds[i]);
        }
    }
}
