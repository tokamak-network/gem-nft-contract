// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../L2/GemFactoryStorage.sol";

library MiningLibrary {

    /**
     * @notice internal function to modify storage variables associated with the gem that is about to mine.
     * @param Gems list of gems
     * @param userMiningToken mapping of the user mining the specific token
     * @param userMiningStartTime the mining start time
     * @param owner token owner
     * @param tokenId token id that is going to mine
     */
    function startMining(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(address => mapping(uint256 => bool)) storage userMiningToken,
        mapping(address => mapping(uint256 => uint256)) storage userMiningStartTime,
        mapping(GemFactoryStorage.Rarity => uint256) storage numberMiningGemsByRarity,
        address owner,
        uint256 tokenId
    ) internal {
        userMiningToken[owner][tokenId] = true;
        userMiningStartTime[owner][tokenId] = block.timestamp;
        Gems[tokenId].isLocked = true;
        Gems[tokenId].miningTry--;
        numberMiningGemsByRarity[Gems[tokenId].rarity]++;
    }

    /**
     * @notice internal function to delete storage variables created when calling startMining.
     * @param Gems list of gems
     * @param userMiningToken mapping of the user mining the specific token
     * @param userMiningStartTime the mining start time
     * @param owner token owner
     * @param tokenId token id that is going to mine
     */
    function cancelMining(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(address => mapping(uint256 => bool)) storage userMiningToken,
        mapping(address => mapping(uint256 => uint256)) storage userMiningStartTime,
        mapping(GemFactoryStorage.Rarity => uint256) storage numberMiningGemsByRarity,
        address owner,
        uint256 tokenId
    ) internal {
        delete userMiningToken[owner][tokenId];
        delete userMiningStartTime[owner][tokenId];
        Gems[tokenId].isLocked = false;
        numberMiningGemsByRarity[Gems[tokenId].rarity]--;
    }
}
