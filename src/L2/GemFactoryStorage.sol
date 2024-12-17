// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

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
        uint256 value; // 27 decimals
        uint256 gemCooldownDueDate; // gem cooldown before user can start mining
        uint256 randomRequestId; // store the random request (if any). it is initially set up to 0
        Rarity rarity; 
        uint8 miningTry; 
        bool isLocked; // Locked if gem is listed on the marketplace
        uint8[4] quadrants; // 4 quadrants
        uint8[2] color; // id of the color
        string tokenURI; // IPFS address of the metadata file 
    }

    struct RequestStatus {
        uint256 tokenId;
        uint256 randomWord;
        uint256 chosenTokenId;
        address requester;
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
    } 

    //---------------------------------------------------------------------------------------
    //-------------------------------------STORAGE-------------------------------------------
    //---------------------------------------------------------------------------------------

    Gem[] public Gems;
    mapping(uint8 => mapping(uint8 => string)) public colorName;
    uint8 public colorsCount;
    uint8[2][] public colors;

    mapping(uint256 => address) public GEMIndexToOwner;
    mapping(address => uint256) public ownershipTokenCount;

    // Mining mappings
    mapping(address => uint256) public tokenMiningByUser;
    mapping(address => mapping(uint256 => bool)) public userMiningToken;
    mapping(address => mapping(uint256 => uint256)) public userMiningStartTime;
    mapping(uint256 => bool) public tokenReadyToMine;
    mapping(Rarity => uint256) public numberMiningGemsByRarity;

    // Random requests mapping
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    bool public paused;

    // Mining storage
    // mining try is uint8 (will be always less than type(uint8).max = 255)
    uint8 internal RareminingTry;
    uint8 internal UniqueminingTry;
    uint8 internal EpicminingTry;
    uint8 internal LegendaryminingTry;
    uint8 internal MythicminingTry;

    uint32 internal RareGemsMiningPeriod;
    uint32 internal UniqueGemsMiningPeriod;
    uint32 internal EpicGemsMiningPeriod;
    uint32 internal LegendaryGemsMiningPeriod;
    uint32 internal MythicGemsMiningPeriod;

    uint32 internal RareGemsCooldownPeriod;
    uint32 internal UniqueGemsCooldownPeriod;
    uint32 internal EpicGemsCooldownPeriod;
    uint32 internal LegendaryGemsCooldownPeriod;
    uint32 internal MythicGemsCooldownPeriod;

    uint32 public callbackGasLimit;

    uint256 internal CommonGemsValue;
    uint256 internal RareGemsValue;
    uint256 internal UniqueGemsValue;
    uint256 internal EpicGemsValue;
    uint256 internal LegendaryGemsValue;
    uint256 internal MythicGemsValue;

    // past random requests Id.
    uint256[] internal requestIds;
    uint256 internal requestCount;

    // contract addresses
    address internal wston;
    address internal ton;
    address internal treasury;
    address internal marketplace;
    address internal airdrop;

    //---------------------------------------------------------------------------------------
    //-------------------------------------EVENTS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // Premining events
    event Created(
        uint256 indexed tokenId, 
        Rarity rarity, 
        uint8[2] color, 
        uint8 miningTry,
        uint256 value,
        uint8[4] quadrants, 
        uint256 cooldownDueDate,
        string tokenURI, 
        address owner
    );
    event TransferGEM(address from, address to, uint256 tokenId, uint256 gemCooldownDueDate);

    // Mining Events
    event GemMiningStarted(uint256 tokenId, address miner, uint256 startMiningTime, uint256 newminingTry);
    event GemMiningClaimed(uint256 tokenId, uint256 chosenTokenId, uint256 minedGemCooldownDueDate, uint256 initialGemCooldownDueDate, address miner);
    event GemMelted(uint256 _tokenId, address _from);
    event RandomGemRequested(uint256 tokenId, uint256 requestNumber);
    event NoGemAvailable(uint256 tokenId, uint256 initialGemCooldownDueDate, address miner);
    event CountGemsByQuadrant(uint256 gemCount, uint256[] tokenIds);
    event MiningCancelled(uint256 _tokenId, address owner, uint256 timestamp);
    event EthSentBack(uint256 amount);

    // Forging Event
    event GemForged(
        address gemOwner,
        uint256[] gemsTokenIds, 
        uint256 newGemCreatedId, 
        Rarity newRarity, 
        uint8[4] forgedQuadrants, 
        uint8[2] color, 
        uint256 newValue
    );
    event ColorValidated(uint8 color_0, uint8 color_1);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

    //storage setter events
    event ColorAdded(uint8 indexed id, string color);
    event BackgroundColorAdded(uint8 indexed id, string backgroundColor);

    //storage modification events
    event GemsCoolDownPeriodModified(
        uint32 RareGemsCooldownPeriod,
        uint32 UniqueGemsCooldownPeriod,
        uint32 EpicGemsCooldownPeriod,
        uint32 LegendaryGemsCooldownPeriod,
        uint32 MythicGemsCooldownPeriod
    );
    event GemsMiningPeriodModified(
        uint32 RareGemsMiningPeriod,
        uint32 UniqueGemsMiningPeriod,
        uint32 EpicGemsMiningPeriod,
        uint32 LegendaryGemsMiningPeriod,
        uint32 MythicGemsMiningPeriod
    );
    event GemsMiningTryModified(
        uint8 RareGemsMiningTry,
        uint8 UniqueGemsMiningTry,
        uint8 EpicGemsMiningTry,
        uint8 LegendaryGemsMiningTry,
        uint8 MythicGemsMiningTry
    );
    event GemsValueModified(
        uint256 CommonGemsValue,
        uint256 RareGemsValue,
        uint256 UniqueGemsValue,
        uint256 EpicGemsValue,
        uint256 LegendaryValue,
        uint256 MythicValue
    );

    event CallBackGasLimitUpdated(uint32 newCallbackGasLimit);

    //---------------------------------------------------------------------------------------
    //-------------------------------------ERRORS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // gem creation errors
    error NewGemInvalidQuadrant(uint8 quadrantIndex, uint8 expectedValue1, uint8 expectedValue2);
    error SumOfQuadrantsTooHigh(uint8 sum, string rarity);
    
    // Forging errors
    error InvalidQuadrant(uint8 quadrant, uint8 value);
    error InvalidSumOfQuadrants();
    error ColorNotExist();

    // Mining errors
    error MismatchedArrayLengths();
    error AddressZero();
    error NotGemOwner();
    error CooldownPeriodNotElapsed();
    error GemIsLocked();
    error GemIsNotLocked();
    error WrongRarity();
    error NoMiningTryLeft();
    error NotMining();
    error GemAlreadyPicked();
    error MiningPeriodNotElapsed();

    // Transfer error
    error SameSenderAndRecipient();
    error TransferFailed();

    // Random fullfil error
    error RequestNotMade();
    error FailedToSendEthBack();

    // access errors
    error UnauthorizedCaller(address caller);
    error ContractPaused();
    error ContractNotPaused();
    error URIQueryForNonexistentToken(uint256 tokenId);
}
