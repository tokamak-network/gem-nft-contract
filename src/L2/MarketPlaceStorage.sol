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
    uint256 internal tonFeesRate;

    address internal gemFactory;
    address internal treasury;
    address internal wston;
    address internal ton;

    uint256 constant public TON_FEES_RATE_DIVIDER = 10000;
    uint256 constant public DECIMALS = 10**27;

    uint256 internal stakingIndex = 10**27;

    bool internal paused = false;
    bool internal initialized = false;

    event GemBought(uint256 tokenId, address payer, address seller, uint256 amount, uint256 gemCoolDownDueDate);
    event GemForSale(uint256 tokenId, address seller, uint256 price);
    event GemRemovedFromSale(address seller, uint256 tokenId);
    event WSTONClaimed(uint256 tokenId, address claimer);
    event SetDiscountRate(uint256 discountRate);
    event SetStakingIndex(uint256 stakingIndex);
    event GemFactoryAddressUpdated(address gemfactory);


    error NoTokens();
    error WrongLength();
    error GemIsNotForSale();
    error NotGemOwner();
    error WrongStakingIndex();
    error WrongPrice();
    error GemIsAlreadyForSaleOrIsMining();
    error AddressZero();
    error WrongSeller();
    error BuyerIsSeller(string errorMessage);
    error Paused();
    error NotPaused();
    error AlreadyInitialized();
    error GemNotApproved();
    error PurchaseFailed();
    error ListingGemFailed();
    error WrongMsgValue();
    error FailedToPay();
    error FailedToSendFeesToTreasury();
}
