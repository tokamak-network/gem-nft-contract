// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MarketPlaceStorage } from "./MarketPlaceStorage.sol";
import { GemFactory } from "./GemFactory.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
}

interface IGemFactory {
    function transferGEMFrom(address _from, address _to, uint256 _tokenId) external; 
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
}


contract MarketPlace is MarketPlaceStorage, GemFactory, ReentrancyGuard {
    using SafeERC20 for IERC20;

    constructor(address coordinator) GemFactory(coordinator) {}

    function initialize(
        address _treasury, 
        address _gemfactory,
        address _titanwston, 
        address _ton, 
        uint256 _discountRate
    ) external {
        require(wston == address(0), "titanwston already initialized");
        require(ton == address(0), "ton already initialized");
        require(_discountRate < 100, "discount rate must be less than 100%");
        wston = _titanwston;
        ton = _ton;
        discountRate = _discountRate;
        treasury = _treasury;
        gemfactory = _gemfactory;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice to buy a GEM listed onto the marketplace
     * @param _tokenId the ID of the token to be transferred
     * @param _paymentMethod The paymentMethod used. if true, user purchases using L2 WSTON if false, user purchases using TON
     */
    function buyGem(uint256 _tokenId, bool _paymentMethod) external whenNotPaused {
        require(_buyGem(_tokenId, msg.sender, _paymentMethod));
    }

    /**
     * @notice put a GEM for sale
     * @param _tokenId the ID of the token to be transferred
     * @param _price price asked for the transaction
     */
    function putGemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused returns (bool) {
        // Approve the MarketPlace contract to transfer the GEM
        IGemFactory(gemfactory).approve(address(this), _tokenId);
        
        require(_putGemForSale(_tokenId, _price, msg.sender), "failed to put gem for sale");
        return true;
    }

    /**
     * @notice put multiple GEMs for sale
     * @param _tokenIds the ID of the token to be transferred
     * @param _prices price asked for the transaction
     */
    function putGemForSale(uint256[] memory _tokenIds, uint256[] memory _prices) external whenNotPaused returns (bool) {
        require(_tokenIds.length != 0, "no tokens");
        require(_tokenIds.length == _prices.length, "wrong length");

        for (uint256 i = 0; i < _tokenIds.length; i++){
            IGemFactory(gemfactory).approve(address(this), _tokenIds[i]);
            require(_putGemForSale(_tokenIds[i], _prices[i], msg.sender));
        }

        return true;
    }

    /**
     * @notice claim WSTON whenever purchase is settled. only callable by the seller
     * @param _tokenId the ID of the token bought
     */
    function claimWSTON(uint256 _tokenId) external whenNotPaused returns (bool) {
        require(_claimWSTON(_tokenId, msg.sender), "failed to claim WSTON");
        return true;
    }

    function setDiscountRate(uint256 _discountRate) external onlyOwner {
        require(_discountRate < 100, "discount rate must be less than 100%");
        discountRate = _discountRate;
        emit SetDiscountRate(_discountRate);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    function _buyGem(uint256 _tokenId, address _payer, bool _paymentMethod) internal nonReentrant returns(bool) {
        require(Gems[_tokenId].isLocked, "Gem not for sale");
        require(_payer != address(0), "zero address");
        require(GEMIndexToOwner[_tokenId] == treasury, "Gem not owned by the treasury");
        require(initialSeller[_tokenId] != address(0), "seller must be different than address 0");
        
        uint256 price = sellingPrice[_tokenId];
        require(price != 0, "wrong price");
        
        //  transfer TON or WSTON to the treasury contract 
        if (_paymentMethod) {
            uint256 discountedGemValue = price - ((price * discountRate) / DISCOUNT_RATE_DIVIDER);     
            IERC20(wston).safeTransferFrom(_payer, treasury, discountedGemValue);
        } else {
            IERC20(ton).safeTransferFrom(_payer, treasury, price);
        }
        // transfer NFT ownership
        ITreasury(treasury).transferTreasuryGEMto(_payer, _tokenId);

        isGemSold[_tokenId] = true;

        emit GemBought(_tokenId, _payer);
        return true;
    }

    function _putGemForSale(uint256 _tokenId, uint256 _price, address _seller) internal nonReentrant returns (bool) {
        require(!Gems[_tokenId].isLocked, "Gem is already for sale");
        require(GEMIndexToOwner[_tokenId] == _seller, "Gem not owned by the treasury");
        require(!userMiningToken[_seller][_tokenId], "user is using this GEM for mining");
        require(_price != 0, "price must be higher than 0");

        sellingPrice[_tokenId] = _price;
        initialSeller[_tokenId] = _seller;
        isGemSold[_tokenId] = false;
    
        IGemFactory(gemfactory).transferGEMFrom(_seller, treasury, _tokenId);
        
        emit GemPutForSale(_tokenId, _seller);
        return true;
    }

    function _claimWSTON(uint256 _tokenId, address _claimer) internal nonReentrant returns (bool) {
        require(initialSeller[_tokenId] == _claimer, "wrong claimer");
        require(sellingPrice[_tokenId] != 0, "wrong selling price");
        require(isGemSold[_tokenId] = true, "Gem is not sold");

        uint256 _sellingPrice = sellingPrice[_tokenId];

        // storage update
        delete sellingPrice[_tokenId];
        delete initialSeller[_tokenId];
        delete isGemSold[_tokenId];

        // transfer WSTON to seller
        IERC20(wston).safeTransferFrom(treasury, _claimer, _sellingPrice);

        emit WSTONClaimed(_tokenId, _claimer);
        return true;
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function getDiscountRate() external view returns (uint256) {
        return discountRate;
    }

    function gemFactory() external view returns (address) {
        return gemfactory;
    }

}