// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../L2/GemFactoryStorage.sol";

library MiningLibrary {
    function startMining(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(address => mapping(uint256 => bool)) storage userMiningToken,
        mapping(address => mapping(uint256 => uint256)) storage userMiningStartTime,
        address owner,
        uint256 tokenId
    ) internal {
        userMiningToken[owner][tokenId] = true;
        userMiningStartTime[owner][tokenId] = block.timestamp;
        Gems[tokenId].isLocked = true;
        Gems[tokenId].miningTry--;
    }

    function cancelMining(
        GemFactoryStorage.Gem[] storage Gems,
        mapping(address => mapping(uint256 => bool)) storage userMiningToken,
        mapping(address => mapping(uint256 => uint256)) storage userMiningStartTime,
        address owner,
        uint256 tokenId
    ) internal {
        delete userMiningToken[owner][tokenId];
        delete userMiningStartTime[owner][tokenId];
        Gems[tokenId].isLocked = false;
    }
}
