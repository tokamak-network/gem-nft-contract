// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


contract RandomPackStorage {

    struct GemPackRequestStatus {
        uint256 randomWord;
        uint256 chosenTokenId;
        address requester;
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
    }

    mapping(uint256 => GemPackRequestStatus) public s_requests; /* requestId --> requestStatus */

    address internal gemFactory;
    address internal treasury;
    address internal ton;

    uint256 internal requestCount;
    uint256 internal randomPackFees; // in TON (18 decimals)
    
    string internal perfectCommonGemURI;

    bool internal paused = false;
    bool internal initialized = false;
    bool internal probInitialized = false;

    // constants
    uint32 internal callbackGasLimit;

    uint8 constant public DIVIDER = 100;
    mapping(uint8 => uint8) internal probabilities; // stores the probability based on the rarity => in percent

    //events
    event RandomGemRequested(address requestor, uint256 requestId);
    event RandomGemToBeTransferred(uint256 tokenId, address newOwner);
    event RandomGemTransferred(uint256 tokenId, address newOwner);
    event CommonGemToBeMinted();
    event CommonGemMinted();
    event RandomPackFeesUpdated(uint256 randomPackFees);
    event TreasuryAddressUpdated(address treasury);
    event GemFactoryAddressUpdated(address gemFactory);
    event PerfectCommonGemURIUpdated(string _tokenURI);
    event CallBackGasLimitUpdated(uint256 _callbackGasLimit);
    event EthSentBack(uint256 amount);

    // errors
    error InvalidAddress();
    error RandomPackFeesEqualToZero();
    error RequestNotMade();
    error FailedToSendEthBack();
    error FailedToPayFees();
    error FailedToSendFeesToTreasury();
    error invalidProbabilities();
    error AlreadyInitialized();
    
}