// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IGemFactory } from "../../../src/interfaces/IGemFactory.sol"; 
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GemFactoryStorage } from "../../../src/L2/GemFactoryStorage.sol";
import { MarketPlaceStorage } from "../../../src/L2/MarketPlaceStorage.sol";
import { GemFactory } from "../../../src/L2/GemFactory.sol";
import {AuthControl} from "../../../src/common/AuthControl.sol";
import "../../../src/proxy/ProxyStorage.sol";

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


contract MockMarketPlaceUpgraded is ProxyStorage, MarketPlaceStorage, ReentrancyGuard, AuthControl {
    using SafeERC20 for IERC20;

    string public commonGemTokenUri;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function initialize(
        address _treasury, 
        address _gemfactory,
        uint256 _tonFeesRate,
        address _wston,
        address _ton
    ) external {
        require(!initialized, "already initialized"); 
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tonFeesRate = _tonFeesRate;
        gemFactory = _gemfactory;
        treasury = _treasury;
        wston = _wston;
        ton = _ton;
        commonGemTokenUri = "";
        initialized = true;
    }

    function setTonFeesRate(uint256 _tonFeesRate) external onlyOwner {
        tonFeesRate = _tonFeesRate;
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
        if(tokenIds.length == 0) {
            revert NoTokens();
        }
        if(tokenIds.length != prices.length) {
            revert WrongLength();
        }

        for (uint256 i = 0; i < tokenIds.length; ++i){
            require(IGemFactory(gemFactory).getApproved(tokenIds[i]) == address(this), "the NFT is not approved");
            require(_putGemForSale(tokenIds[i], prices[i]), "failed to put gem for sale");
        }
    }

    /**
     * @notice Remove a gem that was put for sale
     * @param _tokenId the ID of the token to be removed from the list
     */
    function removeGemForSale(uint256 _tokenId) external whenNotPaused {
        if(gemsForSale[_tokenId].isActive != true) {
            revert GemIsNotForSale();
        }
        if(IGemFactory(gemFactory).ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }

        GemFactory(gemFactory).setIsLocked(_tokenId, false);

        delete gemsForSale[_tokenId];
        emit GemRemovedFromSale(msg.sender, _tokenId);

    }

    function setDiscountRate(uint256 _tonFeesRate) external onlyOwner {
        require(_tonFeesRate < 100, "discount rate must be less than 100%");
        tonFeesRate = _tonFeesRate;
        emit SetDiscountRate(_tonFeesRate);
    }

    function setStakingIndex(uint256 _stakingIndex) external onlyOwner {
        if(_stakingIndex < 1e27) {
            revert WrongStakingIndex();
        }
        stakingIndex = _stakingIndex;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    
    function _putGemForSale(uint256 _tokenId, uint256 _price) internal returns (bool) {
        if(IGemFactory(gemFactory).ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        if(_price == 0) {
            revert WrongPrice();
        }
        if(IGemFactory(gemFactory).isTokenLocked(_tokenId) == true) {
            revert GemIsAlreadyForSaleOrIsMining();
        }   

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
        if(_payer == address(0)) {
            revert AddressZero();
        }
        if(!gemsForSale[_tokenId].isActive) {
            revert GemIsNotForSale();
        }
        
        uint256 price = gemsForSale[_tokenId].price;
        if(price == 0) {
            revert WrongPrice();
        }

        address seller = gemsForSale[_tokenId].seller;
        if(seller == address(0)) {
            revert WrongSeller();
        }

        if(msg.sender == seller && msg.sender == _payer) {
            revert BuyerIsSeller("Use RemoveGemFromList instead");
        }
        
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
        IGemFactory.Gem memory gem = IGemFactory(gemFactory).getGem(_tokenId);
        uint256 gemCoolDownDueDate = gem.gemCooldownDueDate;

        emit GemBought(_tokenId, _payer, seller, price, gemCoolDownDueDate);
        return true;
    }

    function buyCommonGem() external whenNotPaused returns(bool) {
        // we fetch the value of a common gem
        uint256 commonGemValue = IGemFactory(gemFactory).getCommonGemsValue();
        // the function caller pays a WSTON amount equal to the value of the GEM.
        IERC20(wston).safeTransferFrom(msg.sender, treasury, commonGemValue);
        // we mint from scratch a perfect common GEM 
        uint256 newTokenId = ITreasury(treasury).createPreminedGEM(GemFactoryStorage.Rarity.COMMON, [0,0], [1,1,1,1], commonGemTokenUri);
        // the new gem is transferred to the user
        ITreasury(treasury).transferTreasuryGEMto(msg.sender, newTokenId);
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
    
    function getTonFeesRate() external view returns (uint256) {
        return tonFeesRate;
    }

    function getStakingIndex() external view returns(uint256) {
        return stakingIndex;
    }

    function getGemFactoryAddress() external view returns(address) {
        return gemFactory;
    }

    function getTreasuryAddress() external view returns (address) {
        return treasury;
    }
 
}