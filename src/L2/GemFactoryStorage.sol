// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract GemFactoryStorage {

    struct Gem {
        uint256 tokenId;
        bytes1 quadrants;
        string color;
        string colorStyle; //deterministic =>we dont need it
        string backgroundColor; //deterministic =>we dont need it
        string backgroundColorStyle; //deterministic =>we dont need it
        uint256 gemCooldownPeriod; // gem cooldown before user can start mining
        uint256 miningPeriod; // Mining delay before claiming
        bool isLocked; // Locked if gem is listed on the marketplace
        uint128 value; // 27 decimals
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
    mapping(uint256 => bool) public tokenReadyToMine;

    // Random requests mapping
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    bool public paused;

    // Staking index trackers
    uint256 public L1StakingIndex;
    uint256 public estimatedStakingIndexIncreaseRate;

    // Mining storage
    uint256 public CommonMiningFees;
    uint256 public RareMiningFees;
    uint256 public UniqueMiningFees;

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
    event Created(uint256 tokenId, bytes1 quadrants, string color, uint256 value, address owner);
    event TransferGEM(address from, address to, uint256 tokenId);

    // Mining Events
    event GemMiningStarted(uint256 tokenId, address miner);
    event GemMiningClaimed(uint256 tokenId, address miner);
    event GemMelted(uint256 _tokenId, address _from);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);
}
