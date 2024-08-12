// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract GemFactoryStorage {

    enum Rarity {
        COMMON,
        RARE,
        UNIQUE,
        EPIC,
        LEGENDARY,
        MYTHIC
    }

    struct Gem {
        uint256 tokenId;
        Rarity rarity;
        uint8[4] quadrants; // 4 quadrants
        uint8[2] color; // id of the color
        uint256 gemCooldownPeriod; // gem cooldown before user can start mining
        uint256 miningPeriod; // Mining delay before claiming
        uint256 miningPower;
        bool isLocked; // Locked if gem is listed on the marketplace
        uint256 value; // 27 decimals
        string tokenURI; // IPFS address of the metadata file
        uint256 randomRequestId; // store the random request (if any). it is initially set up to 0
    }

    struct RequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
        uint256 chosenTokenId;
        address requester;
    }

    Gem[] public Gems;
    mapping(uint8 => string) public customColors;
    uint8 public customColorsCount;
    string[] public colors;

    mapping(uint8 => string) public customBackgroundColors;
    uint8 public customBackgroundColorsCount;
    string[] public backgroundColors;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(address => uint256) public ownershipTokenCount;

    // Mining mappings
    mapping(address => bool) public isUserMining;
    mapping(address => uint256) public tokenMiningByUser;
    mapping(address => mapping(uint256 => bool)) public userMiningToken;
    mapping(address => mapping(uint256 => uint256)) public userMiningStartTime;
    mapping(uint256 => bool) public tokenReadyToMine;

    // Random requests mapping
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    bool public paused;

    // Mining storage
    uint256 public CommonMiningPower;
    uint256 public RareMiningPower;
    uint256 public UniqueMiningPower;
    uint256 public EpicMiningPower;
    uint256 public LegendaryMiningPower;
    uint256 public MythicMiningPower;

    uint256 public CommonGemsValue;
    uint256 public RareGemsValue;
    uint256 public UniqueGemsValue;
    uint256 public EpicGemsValue;
    uint256 public LegendaryGemsValue;
    uint256 public MythicGemsValue;

    uint256 public CommonGemsMiningPeriod;
    uint256 public RareGemsMiningPeriod;
    uint256 public UniqueGemsMiningPeriod;
    uint256 public EpicGemsMiningPeriod;
    uint256 public LegendaryGemsMiningPeriod;
    uint256 public MythicGemsMiningPeriod;

    uint256 public CommonGemsCooldownPeriod;
    uint256 public RareGemsCooldownPeriod;
    uint256 public UniqueGemsCooldownPeriod;
    uint256 public EpicGemsCooldownPeriod;
    uint256 public LegendaryGemsCooldownPeriod;
    uint256 public MythicGemsCooldownPeriod;

    // past random requests Id.
    uint256[] public requestIds;
    uint256 public requestCount;

    // color storage
    uint8 public numberOfSolidColors;

    // contract addresses
    address public wston;
    address public ton;
    address public treasury;
    address public marketplace;
    address public drbcoordinator;

    // constants
    uint32 public constant CALLBACK_GAS_LIMIT = 210000;

    /**
     * EVENTS **
     */

    // Premining events
    event Created(
        uint256 indexed tokenId, 
        Rarity rarity, 
        uint8[2] color, 
        uint256 value,
        uint8[4] quadrants, 
        uint256 miningPeriod,
        uint256 cooldownPeriod,
        string tokenURI, 
        address owner
    );
    event TransferGEM(address from, address to, uint256 tokenId);

    // Mining Events
    event GemMiningStarted(uint256 tokenId, address miner, uint256 startMiningTime, uint256 newMiningPower);
    event GemMiningClaimed(uint256 tokenId, address miner);
    event GemMelted(uint256 _tokenId, address _from);

    // Forging Event
    event GemForged(
        uint256[] GemsTokenIds, 
        uint256 newGemCreatedId, 
        Rarity newRarity, 
        uint8[4] forgedQuadrants, 
        uint8[2] color, 
        uint256 newValue
    );

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

    //storage setter events
    event ColorAdded(uint8 indexed id, string color);
    event BackgroundColorAdded(uint8 indexed id, string backgroundColor);
}
