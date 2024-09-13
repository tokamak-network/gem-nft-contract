// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;


contract RandomPackStorage {

    struct GemPackRequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
        uint256 chosenTokenId;
        address requester;
    }

    mapping(uint256 => GemPackRequestStatus) public s_requests; /* requestId --> requestStatus */


    address public gemFactory;
    address public treasury;
    address public ton;
    address public drbcoordinator;

    bool paused = false;

    // constants
    uint32 public callbackGasLimit;

    uint256 public requestCount;
    uint256 public randomPackFees; // in TON (18 decimals)
    string public perfectCommonGemURI;

    event RandomGemToBeTransferred(uint256 tokenId, address newOwner);
    event RandomGemTransferred(uint256 tokenId, address newOwner);
    event CommonGemToBeMinted();
    event CommonGemMinted();
}