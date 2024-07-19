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
        bool isForSale;
        bool isMinable;
        uint256 value; // 27 decimals
    }

    Gem[] public Gems;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(address => uint256) public ownershipTokenCount;
    mapping(uint256 => address) public GEMIndexToApproved;
    mapping(uint256 => address) public gemAllowedToAddress;

    // Mining mappings
    mapping(address => bool) public isUserMining;
    mapping(address => mapping(uint256 => bool)) public userMiningToken;
    mapping(address => mapping(uint256 => uint256)) public userMiningStartTime;

    bool public paused;

    uint256 public L1StakingIndex;
    uint256 public estimatedStakingIndexIncreaseRate;

    // Mining storage
    uint256 public miningCooldown;
    uint256 public BaseMiningFees;
    uint256 public CommonMiningFees;
    uint256 public UncommonMiningFees;
    uint256 public RareMiningFees;


    address internal titanwston;
    address internal ton;
    address internal treasury;

    /**
     * EVENTS **
     */

    // Premining events
    event Created(uint256 tokenId, Rarity rarity, bytes4 quadrants, string color, uint256 value, address owner);
    event TransferGEM(address from, address to, uint256 tokenId);

    // Mining Events
    event GemMining(uint256 tokenId, address miner);
    event GemMiningClaimed(uint256 tokenId, address miner);
}
