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
        bytes2 quadrants;
        string color;
        string colorStyle;
        string backgroundColor;
        string backgroundColorStyle;
        uint256 cooldownPeriod;
        bool isForSale;
        uint128 value; // 27 decimals
        string tokenURI; // IPFS address of the metadata file
    }

    struct RequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
        address requester;
    }

    Gem[] public Gems;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(address => uint256) public ownershipTokenCount;
    mapping(uint256 => address) public GEMIndexToApproved;
    mapping(uint256 => address) public gemAllowedToAddress;

    // Mining mappings
    mapping(address => bool) public isUserMining;
    mapping(address => uint256) public tokenMiningByUser;
    mapping(address => mapping(uint256 => bool)) public userMiningToken;
    mapping(address => mapping(uint256 => uint256)) public userMiningStartTime;

    // Random requests mapping
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    bool public paused;

    // Staking index trackers
    uint256 public L1StakingIndex;
    uint256 public estimatedStakingIndexIncreaseRate;

    // Mining storage
    uint256 public BaseMiningFees;
    uint256 public CommonMiningFees;
    uint256 public UncommonMiningFees;
    uint256 public RareMiningFees;

    // past random requests Id.
    uint256[] public requestIds;
    uint256 public requestCount;
    uint256 public lastRequestId;


    address public wston;
    address public ton;
    address public treasury;

    // constants
    uint32 public constant CALLBACK_GAS_LIMIT = 210000;

    /**
     * EVENTS **
     */

    // Premining events
    event Created(uint256 tokenId, Rarity rarity, bytes4 quadrants, string color, uint256 value, address owner);
    event TransferGEM(address from, address to, uint256 tokenId);

    // Mining Events
    event GemMiningStarted(uint256 tokenId, address miner);
    event GemMiningClaimed(uint256 tokenId, address miner);
    event GemMelted(uint256 _tokenId, address _from);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);
}
