// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GemFactoryStorage } from "./GemFactoryStorage.sol";
import { MarketPlaceStorage } from "./MarketPlaceStorage.sol";
import { GemFactory } from "./GemFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../proxy/ProxyStorage.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
    function createPreminedGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color, 
        uint8[4] memory _quadrants,  
        string memory _tokenURI
    ) external returns (uint256);
    function approveWstonForMarketplace(uint256 amount) external;
}


contract MarketPlace is MarketPlaceStorage, ReentrancyGuard, Ownable, ProxyStorage {
    using SafeERC20 for IERC20;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor() Ownable(msg.sender) {}

    function initialize(
        address _treasury, 
        address _gemfactory,
        uint256 _tonFeesRate,
        address _wston,
        address _ton
    ) external onlyOwner {
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        tonFeesRate = _tonFeesRate;
        gemFactory = _gemfactory;
        treasury = _treasury;
        wston = _wston;
        ton = _ton;
        commonGemTokenUri = "";
    }

    function setCommonGemTokenUri(string memory _tokenURI) external onlyOwner {
        commonGemTokenUri = _tokenURI;
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
        require(IGemFactory(gemFactory).getApproved(_tokenId) == address(this), "the NFT is not approved");
        require(_putGemForSale(_tokenId, _price), "failed to put gem for sale");
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
            require(IGemFactory(gemFactory).getApproved(tokenIds[i]) == address(this), "the NFT is not approved");
            require(_putGemForSale(tokenIds[i], prices[i]), "failed to put gem for sale");
        }
    }

    /**
     * @notice Remove a gem that was put for sale
     * @param _tokenId the ID of the token to be removed from the list
     */
    function removeGemForSale(uint256 _tokenId) external whenNotPaused {
        require(gemsForSale[_tokenId].isActive == true, "Gem is not for sale");
        require(IGemFactory(gemFactory).ownerOf(_tokenId) == msg.sender, "Not the owner of the GEM");

        GemFactory(gemFactory).setIsLocked(_tokenId, false);

        delete gemsForSale[_tokenId];
        emit GemRemovedFromSale(_tokenId);

    }

    function buyCommonGem() external whenNotPaused returns(uint256 newTokenId) {
        // we fetch the value of a common gem
        uint256 commonGemValue = IGemFactory(gemFactory).CommonGemsValue();
        // the function caller pays a WSTON amount equal to the value of the GEM.
        IERC20(wston).safeTransferFrom(msg.sender, treasury, commonGemValue);
        // we mint from scratch a perfect common GEM 
        newTokenId = ITreasury(treasury).createPreminedGEM(GemFactoryStorage.Rarity.COMMON, [0,0], [1,1,1,1], commonGemTokenUri);
        // the new gem is transferred to the user
        ITreasury(treasury).transferTreasuryGEMto(msg.sender, newTokenId);
    }

    function setDiscountRate(uint256 _tonFeesRate) external onlyOwner {
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        tonFeesRate = _tonFeesRate;
        emit SetDiscountRate(_tonFeesRate);
    }

    function setStakingIndex(uint256 _stakingIndex) external onlyOwner {
        require(stakingIndex >= 1, "staking index must be greater or equal to 1");
        stakingIndex = _stakingIndex;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    
    function _putGemForSale(uint256 _tokenId, uint256 _price) internal returns (bool) {
        require(IGemFactory(gemFactory).ownerOf(_tokenId) == msg.sender, "Not the owner of the GEM");
        require(_price > 0, "Price must be greater than zero");
        require(IGemFactory(gemFactory).isTokenLocked(_tokenId) == false, "Gem is already for sale or mining");

        GemFactory(gemFactory).setIsLocked(_tokenId, true);

        gemsForSale[_tokenId] = Sale({
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        
        emit GemForSale(_tokenId, msg.sender, _price);
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
            IERC20(wston).transferFrom(_payer, seller, price);
        } else {
            uint256 wtonPrice = (price * stakingIndex) / DECIMALS;
            uint256 totalprice = _toWAD(wtonPrice + ((wtonPrice * tonFeesRate) / TON_FEES_RATE_DIVIDER));
            IERC20(ton).transferFrom(_payer, treasury, totalprice); // 18 decimals
            if (seller != treasury) {
                ITreasury(treasury).approveWstonForMarketplace(price);
                IERC20(wston).transferFrom(treasury, seller, price); // 27 decimals
            }
        }

        gemsForSale[_tokenId].isActive = false;
        IGemFactory(gemFactory).setIsLocked(_tokenId, false);
        // transfer NFT ownership
        IGemFactory(gemFactory).transferFrom(seller, _payer, _tokenId);
        

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
}