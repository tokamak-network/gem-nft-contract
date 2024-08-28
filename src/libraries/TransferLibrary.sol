// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../L2/GemFactoryStorage.sol";

library TransferLibrary {
    function transferGem(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(uint256 => address) storage GEMIndexToOwner,
        mapping(address => uint256) storage ownershipTokenCount,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        Gems[tokenId].gemCooldownPeriod = block.timestamp + getCooldownPeriod(Gems[tokenId].rarity);
        ownershipTokenCount[to]++;
        GEMIndexToOwner[tokenId] = to;
        ownershipTokenCount[from]--;
    }

    function getCooldownPeriod(GemFactoryStorage.Rarity rarity) internal pure returns (uint256) {
        if (rarity == GemFactoryStorage.Rarity.COMMON) return 1 days;
        if (rarity == GemFactoryStorage.Rarity.RARE) return 2 days;
        if (rarity == GemFactoryStorage.Rarity.UNIQUE) return 3 days;
        if (rarity == GemFactoryStorage.Rarity.EPIC) return 4 days;
        if (rarity == GemFactoryStorage.Rarity.LEGENDARY) return 5 days;
        if (rarity == GemFactoryStorage.Rarity.MYTHIC) return 6 days;
        revert("Invalid rarity");
    }
}
