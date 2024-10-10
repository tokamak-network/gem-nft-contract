// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GemFactoryStorage } from "./GemFactoryStorage.sol";
import { MarketPlaceStorage } from "./MarketPlaceStorage.sol";
import { GemFactory } from "./GemFactory.sol";
import {AuthControl} from "../common/AuthControl.sol";
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

/**
 * @title MarketPlace
 * @dev The MarketPlace contract facilitates the buying and selling of GEM tokens within the ecosystem.
 * It provides a platform for users to list their GEMs for sale, purchase GEMs using different payment methods,
 * and manage the sale status of their GEMs. The contract integrates with the GemFactory and Treasury contracts
 * to ensure transactions and handling of GEM tokens and payments.
 * - TON: Users can pay with TON tokens, with a fee applied based on the configured fee rate.
 * - WSTON: Users can also pay with WSTON tokens, which are transferred directly to the seller.
 **/
contract MarketPlace is ProxyStorage, MarketPlaceStorage, ReentrancyGuard, AuthControl {
    using SafeERC20 for IERC20;

    /**
     * @notice Modifier to ensure the contract is not paused.
     */
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    /**
     * @notice Modifier to ensure the contract is paused.
     */
    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    /**
     * @notice Pauses the contract, preventing certain actions.
     * @dev Can only be called by the owner when the contract is not paused.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @notice Unpauses the contract, allowing actions to be performed.
     * @dev Can only be called by the owner when the contract is paused.
     */
    function unpause() public onlyOwner whenNotPaused {
        paused = false;
    }

    /**
     * @notice Initializes the marketplace contract with the given parameters.
     * @param _treasury Address of the treasury contract.
     * @param _gemfactory Address of the gem factory contract.
     * @param _tonFeesRate Fee rate for TON transactions.
     * @param _wston Address of the WSTON token.
     * @param _ton Address of the TON token.
     */
    function initialize(
        address _treasury, 
        address _gemfactory,
        uint256 _tonFeesRate,
        address _wston,
        address _ton
    ) external {
        if (initialized) revert AlreadyInitialized();
        if (_tonFeesRate >= 10000) revert WrongDiscountRate(); // less than 100%
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tonFeesRate = _tonFeesRate; // in bps (1% = 100bps)
        gemFactory = _gemfactory;
        treasury = _treasury;
        wston = _wston;
        ton = _ton;
        initialized = true;
    }

    /**
     * @notice Sets the discount rate for TON fees.
     * @param _tonFeesRate New discount rate for TON fees.
     */
    function setDiscountRate(uint256 _tonFeesRate) external onlyOwner {
        if(_tonFeesRate >= 100) {
            revert WrongDiscountRate();
        }
        tonFeesRate = _tonFeesRate;
        emit SetDiscountRate(_tonFeesRate);
    }

    /**
     * @notice Sets the staking index. note that this function is mainly used by the oracle each time a deposit is made on L1WSTON contract.
     * @param _stakingIndex New staking index.
     */
    function setStakingIndex(uint256 _stakingIndex) external onlyOwner {
        if(_stakingIndex < 1e27) {
            revert WrongStakingIndex();
        }
        stakingIndex = _stakingIndex;
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
        if (!_buyGem(_tokenId, msg.sender, _paymentMethod)) revert PurchaseFailed();
    }

    /**
     * @notice put a GEM for sale
     * @param _tokenId the ID of the token to be transferred
     * @param _price price asked for the transaction
     */
    function putGemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused {
        if (IGemFactory(gemFactory).getApproved(_tokenId) != address(this)) revert GemNotApproved();
        if (!_putGemForSale(_tokenId, _price)) revert ListingGemFailed();
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
            if (IGemFactory(gemFactory).getApproved(tokenIds[i]) != address(this)) revert GemNotApproved();
            if (!_putGemForSale(tokenIds[i], prices[i])) revert ListingGemFailed();
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
        emit GemRemovedFromSale(_tokenId);

    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Internal function to put a GEM for sale.
     * @param _tokenId The ID of the token to be transferred.
     * @param _price Price asked for the transaction.
     * @return bool Returns true if the operation is successful.
     */
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
    
    /**
     * @notice Internal function to buy a GEM.
     * @param _tokenId The ID of the token to be transferred.
     * @param _payer Address of the payer.
     * @param _paymentMethod The payment method used.
     * @return bool Returns true if the operation is successful.
     */
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

    function getStakingIndex() external view returns(uint256) {
        return stakingIndex;
    }
}