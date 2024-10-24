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

    bool paused = false;

    // constants
    uint32 internal callbackGasLimit;

    event RandomGemRequested(address requestor);
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

    error InvalidAddress();
    error RandomPackFeesEqualToZero();
    error RequestNotMade();
    error FailedToSendEthBack();
    
}