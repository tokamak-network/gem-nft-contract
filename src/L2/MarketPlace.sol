// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
        address treasury, 
        address gemfactory,
        uint256 _tonFeesRate,
        address _wston,
        address _ton
    ) external {
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        tonFeesRate = _tonFeesRate;
        _gemFactory = gemfactory;
        _treasury = treasury;
        wston_ = _wston;
        ton_ = _ton;
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
    function putGemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused {
        require(_putGemForSale(_tokenId, _price, msg.sender), "failed to put gem for sale");
    }

    /**
     * @notice put multiple GEMs for sale
     * @param tokenIds the ID of the token to be transferred
     * @param prices price asked for the transaction
     */
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external whenNotPaused {
        require(tokenIds.length != 0, "no tokens");
        require(tokenIds.length == prices.length, "wrong length");

        for (uint256 i = 0; i < tokenIds.length; i++){
            require(_putGemForSale(tokenIds[i], prices[i], msg.sender), "failed to put gem for sale");
        }
    }

    function setDiscountRate(uint256 _tonFeesRate) external onlyOwner {
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        tonFeesRate = _tonFeesRate;
        emit SetDiscountRate(_tonFeesRate);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    
    function _putGemForSale(uint256 _tokenId, uint256 _price, address _seller) internal returns (bool) {
        require(GemFactory(_gemFactory).ownerOf(_tokenId) == _seller, "Not the owner of the GEM");
        require(_price > 0, "Price must be greater than zero");
        require(GemFactory(_gemFactory).isTokenLocked(_tokenId) == false, "Gem is already for sale or mining");

        GemFactory(_gemFactory).setIsLocked(_tokenId, true);

        gemsForSale[_tokenId] = Sale({
            seller: _seller,
            price: _price,
            isActive: true
        });

        emit GemForSale(_tokenId, _seller, _price);
        return true;
    }
    
    function _buyGem(uint256 _tokenId, address _payer, bool _paymentMethod) internal nonReentrant returns(bool) {
        require(_payer != address(0), "zero address");
        require(gemsForSale[_tokenId].isActive, "not for sale");
        
        uint256 price = gemsForSale[_tokenId].price;
        require(price != 0, "wrong price");

        address seller = gemsForSale[_tokenId].seller;
        require(seller != address(0), "wrong seller");
        
        //  transfer TON or WSTON to the treasury contract 
        if (_paymentMethod) {     
            IERC20(wston_).safeTransferFrom(_payer, seller, price);
        } else {
            uint256 totalprice = _toWAD(price + ((price * tonFeesRate) / TON_FEES_RATE_DIVIDER));
            IERC20(ton_).safeTransferFrom(_payer, _treasury, totalprice); // 18 decimals
            IERC20(wston_).safeTransferFrom(_treasury, seller, price); // 27 decimals
        }

        gemsForSale[_tokenId].isActive = false;
        GemFactory(_gemFactory).setIsLocked(_tokenId, false);
        // transfer NFT ownership
        GemFactory(_gemFactory).transferFrom(seller, _payer, _tokenId);
        

        emit GemBought(_tokenId, _payer, seller, price);
        return true;
    }

    /**
     * @dev transform WAD to RAY
     */
    function _toRAY(uint256 v) internal pure returns (uint256) {
        return v * 10 ** 9;
    }

    /**
     * @dev transform RAY to WAD
     */
    function _toWAD(uint256 v) internal pure returns (uint256) {
        return v / 10 ** 9;
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function getTonFeesRate() external view returns (uint256) {
        return tonFeesRate;
    }

    function gemFactory() external view returns (address) {
        return _gemFactory;
    }

}