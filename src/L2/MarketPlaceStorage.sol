// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MarketPlaceStorage {

    // discount rate in percentage
    uint256 public discountRate;

    uint256 constant public DISCOUNT_RATE_DIVIDER = 100;

    event GemBought(uint256 tokenId, address payer);
    event SetDiscountRate(uint256 discountRate);
}
