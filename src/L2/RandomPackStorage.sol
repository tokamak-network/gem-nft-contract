// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


contract RandomPackStorage {

    struct GemPackRequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
        uint256 chosenTokenId;
        address requester;
    }

    mapping(uint256 => GemPackRequestStatus) public s_requests; /* requestId --> requestStatus */


    address internal gemFactory;
    address internal treasury;
    address internal ton;

    bool paused = false;

    // constants
    uint32 internal callbackGasLimit;

    uint256 internal requestCount;
    uint256 internal randomPackFees; // in TON (18 decimals)
    string internal perfectCommonGemURI;

    event RandomGemToBeTransferred(uint256 tokenId, address newOwner);
    event RandomGemTransferred(uint256 tokenId, address newOwner);
    event CommonGemToBeMinted();
    event CommonGemMinted();

    error InvalidAddress();
    error RandomPackFeesEqualToZero();
    error RequestNotMade();
    
}