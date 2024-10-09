// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract MarketPlaceStorage {

    struct Sale {
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Sale) public gemsForSale;

    // Fees rate for purchasing using ton (rate in percentage)
    uint256 public tonFeesRate;

    address public gemFactory;
    address public treasury;
    address public wston;
    address public ton;

    string public commonGemTokenUri;

    uint256 constant public TON_FEES_RATE_DIVIDER = 100;
    uint256 constant public DECIMALS = 10**27;

    uint256 public stakingIndex = 10**27;

    bool public paused = false;
    bool internal initialized = false;

    event GemBought(uint256 tokenId, address payer, address seller, uint256 amount);
    event GemForSale(uint256 tokenId, address seller, uint256 price);
    event GemRemovedFromSale(uint256 tokenId);
    event WSTONClaimed(uint256 tokenId, address claimer);
    event SetDiscountRate(uint256 discountRate);


    error NoTokens();
    error WrongLength();
    error GemIsNotForSale();
    error NotGemOwner();
    error WrongDiscountRate();
    error WrongStakingIndex();
    error WrongPrice();
    error GemIsAlreadyForSaleOrIsMining();
    error AddressZero();
    error WrongSeller();
    error BuyerIsSeller(string errorMessage);
}
