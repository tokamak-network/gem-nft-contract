// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MarketPlaceStorage {

    struct RandomRequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
    }

    mapping(uint256 => RandomRequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public randomRequestIds;
    uint256 public randomRequestCount;
    uint256 public randomLastRequestId;

    // discount rate in percentage
    uint256 public discountRate;

    uint32 public constant CALLBACK_GAS_LIMIT = 83011;

    uint256 constant public DISCOUNT_RATE_DIVIDER = 100;

    event GemBought(uint256 tokenId, address payer);
    event SetDiscountRate(uint256 discountRate);
}
