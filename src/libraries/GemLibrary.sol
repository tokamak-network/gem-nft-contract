// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../L2/GemFactoryStorage.sol";

library GemLibrary {
    function createGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address owner,
        GemFactoryStorage.Rarity rarity,
        uint8[2] memory color,
        uint8[4] memory quadrants,
        uint256 value,
        uint256 miningPeriod,
        uint256 gemCooldownPeriod,
        uint256 miningTry,
        string memory tokenURI
    ) internal returns (uint256) {
        GemFactoryStorage.Gem memory newGem = GemFactoryStorage.Gem({
            tokenId: 0,
            rarity: rarity,
            quadrants: quadrants,
            color: color,
            value: value,
            miningPeriod: miningPeriod,
            gemCooldownPeriod: gemCooldownPeriod,
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
