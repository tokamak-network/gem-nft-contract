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
        uint256 value;
        address owner;
    }

    Gem[] public Gems;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(uint256 => bool) public PreMintedGEMAvailable;
    mapping(address => uint256) ownershipTokenCount;
    mapping(uint256 => address) public GEMIndexToApproved;
    mapping(uint256 => address) public gemAllowedToAddress;

    /**
     * EVENTS **
     */

    event Created(uint256 tokenId, Rarity rarity, bytes4 quadrants, string color, uint256 value, address owner);
    event TransferTKGEM(address from, address to, uint256 tokenId);
}
