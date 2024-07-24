// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract MarketPlaceStorage {

    address internal gemfactory;
    // discount rate in percentage
    uint256 public discountRate;

    uint256 constant public DISCOUNT_RATE_DIVIDER = 100;

    mapping(uint256 => address) public initialSeller;
    mapping(uint256 => uint256) public sellingPrice;
    mapping(uint256 => bool) public isGemSold;

    event GemBought(uint256 tokenId, address payer);
    event GemPutForSale(uint256 tokenId, address seller);
    event WSTONClaimed(uint256 tokenId, address claimer);
    event SetDiscountRate(uint256 discountRate);
}
