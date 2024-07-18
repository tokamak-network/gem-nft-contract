// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract GemFactoryStorage {
    enum Rarity {
        BASE,
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY,
        HEIRLOOM
    }

    struct Gem {
        uint256 tokenId;
        Rarity rarity;
        bytes4 quadrants;
        string color;
        string colorStyle;
        string backgroundColor;
        string backgroundColorStyle;
        uint256 cooldownPeriod;
        uint256 value;
    }

    Gem[] public Gems;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(uint256 => bool) public PreMintedGEMAvailable;
    mapping(address => uint256) ownershipTokenCount;
    mapping(uint256 => address) public GEMIndexToApproved;
    mapping(uint256 => address) public gemAllowedToAddress;

    bool public paused;

    /**
     * EVENTS **
     */

    event Created(uint256 tokenId, Rarity rarity, bytes4 quadrants, string color, uint256 value, address owner);
    event TransferGEM(address from, address to, uint256 tokenId);
}
