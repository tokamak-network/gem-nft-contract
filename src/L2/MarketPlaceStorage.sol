// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract MarketPlaceStorage {

    struct Sale {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Sale) public gemsForSale;

    // Fees rate for purchasing using ton (rate in percentage)
    uint256 public tonFeesRate;

    address internal _gemFactory;
    address internal _treasury;
    address internal wston_;
    address internal ton_;

    uint256 constant public TON_FEES_RATE_DIVIDER = 100;
    uint256 constant public DECIMALS = 10**27;

    uint256 public stakingIndex = 1;

    event GemBought(uint256 tokenId, address payer, address seller, uint256 amount);
    event GemForSale(uint256 tokenId, address seller, uint256 price);
    event WSTONClaimed(uint256 tokenId, address claimer);
    event SetDiscountRate(uint256 discountRate);
}
