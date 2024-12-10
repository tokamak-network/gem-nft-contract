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
 * @title MarketPlace to be deployed on Thanos network only as it considers TON as a native token
 * @author TOKAMAK OPAL TEAM
 * @dev The MarketPlace contract facilitates the buying and selling of GEM tokens within the ecosystem.
 * It provides a platform for users to list their GEMs for sale, purchase GEMs using different payment methods,
 * and manage the sale status of their GEMs. The contract integrates with the GemFactory and Treasury contracts
 * to ensure transactions and handling of GEM tokens and payments.
 * - TON: Users can pay with TON tokens, with a fee applied based on the configured fee rate.
 * - WSTON: Users can also pay with WSTON tokens, which are transferred directly to the seller.
 * @dev this contract is meant to be deployed on Titan only (does not consider TON as a native token)
 **/
contract MarketPlaceThanos is ProxyStorage, MarketPlaceStorage, ReentrancyGuard, AuthControl {
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
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @notice we implement the receive function in order to receive TON (as a native token) 
     */
    receive() external payable {
        // we send the funds to the treasury
        (bool success,) = treasury.call{value: msg.value}("");
        if(!success) {
            revert FailedToSendFeesToTreasury();
        }
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the marketplace contract with the given parameters.
     * @param _treasury Address of the treasury contract.
     * @param _gemfactory Address of the gem factory contract.
     * @param _tonFeesRate Fee rate for TON transactions.
     * @param _wston Address of the WSTON token.
     */
    function initialize(
        address _treasury, 
        address _gemfactory,
        uint256 _tonFeesRate,
        address _wston
    ) external {
        if (initialized) revert AlreadyInitialized();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tonFeesRate = _tonFeesRate; // in bps (1% = 100bps)
        gemFactory = _gemfactory;
        treasury = _treasury;
        wston = _wston;
        initialized = true;
    }

    /**
     * @notice Sets the discount rate for TON fees.
     * @param _tonFeesRate New discount rate for TON fees.
     * @dev The discount rate must be less than 100%.
     */
    function setDiscountRate(uint256 _tonFeesRate) external onlyOwner {
        // Update the TON fee rate
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
        // Update the staking index
        stakingIndex = _stakingIndex;
        emit SetStakingIndex(_stakingIndex);
    }

    /**
     * @notice updates the gemfactory proxy address
     * @param _gemFactory New gemFactory proxy address.
     */
    function setGemFactory(address _gemFactory) external onlyOwner {
        gemFactory = _gemFactory;
        emit GemFactoryAddressUpdated(_gemFactory);
    }

    /**
     * @notice updates the wston token address
     * @param _wston New wston token address
     */
    function setWston(address _wston) external onlyOwner {
        wston = _wston;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Allows a user to buy a GEM listed on the marketplace.
     * @param _tokenId The ID of the token to be purchased.
     * @param _paymentMethod The payment method used. If true, the user purchases using L2 WSTON; if false, using TON.
     * @dev This function handles the purchase process, including payment and transfer of ownership.
     */
    function buyGem(uint256 _tokenId, bool _paymentMethod) external payable whenNotPaused {
        // Attempt to buy the GEM, revert if unsuccessful
        if (!_buyGem(_tokenId, msg.sender, _paymentMethod)) revert PurchaseFailed();
    }

    /**
     * @notice Lists a GEM for sale on the marketplace.
     * @param _tokenId The ID of the token to be listed for sale.
     * @param _price The price at which the GEM is listed.
     * @dev The GEM must be approved for transfer for the marketplace contract before it can be listed.
     */
    function putGemForSale(uint256 _tokenId, uint256 _price) external whenNotPaused {
        // Ensure the GEM is approved for transfer
        if (IGemFactory(gemFactory).getApproved(_tokenId) != address(this)) revert GemNotApproved();
        // Attempt to list the GEM for sale, revert if unsuccessful
        if (!_putGemForSale(_tokenId, _price)) revert ListingGemFailed();
    }

    /**
     * @notice Lists multiple GEMs for sale on the marketplace.
     * @param tokenIds An array of token IDs to be listed for sale.
     * @param prices An array of prices corresponding to each GEM.
     * @dev Each GEM must be approved for transfer by the marketplace contract before it can be listed.
     */
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external whenNotPaused {
        uint256 tokenIdsLength = tokenIds.length;
        uint256 pricesLength = prices.length;
        // Ensure there are tokens to list
        if(tokenIdsLength == 0) {
            revert NoTokens();
        }
        // Ensure the lengths of token IDs and prices match
        if(tokenIdsLength != pricesLength) {
            revert WrongLength();
        }

        // Iterate over each token to list them for sale
        for (uint256 i = 0; i < tokenIdsLength; ++i){
            // Ensure each GEM is approved for transfer
            if (IGemFactory(gemFactory).getApproved(tokenIds[i]) != address(this)) revert GemNotApproved();
            // Attempt to list each GEM for sale, revert if unsuccessful
            if (!_putGemForSale(tokenIds[i], prices[i])) revert ListingGemFailed();
        }
    }

    /**
     * @notice Removes a GEM from being listed for sale on the marketplace.
     * @param _tokenId The ID of the token to be removed from sale.
     * @dev Only the owner of the GEM can remove it from sale.
     */
    function removeGemForSale(uint256 _tokenId) external whenNotPaused {
        // Ensure the GEM is currently listed for sale
        if(gemsForSale[_tokenId].isActive != true) {
            revert GemIsNotForSale();
        }
        // Ensure the caller is the owner of the GEM
        if(IGemFactory(gemFactory).ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }

        // Unlock the GEM and remove it from the sale list
        GemFactory(gemFactory).setIsLocked(_tokenId, false);
        delete gemsForSale[_tokenId];
        emit GemRemovedFromSale(msg.sender, _tokenId);

    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Internal function to list a GEM for sale.
     * @param _tokenId The ID of the token to be listed.
     * @param _price The price at which the GEM is listed.
     * @return bool Returns true if the operation is successful.
     * @dev This function checks ownership and approval before listing the GEM.
     */
    function _putGemForSale(uint256 _tokenId, uint256 _price) internal returns (bool) {
        // Ensure the caller is the owner of the GEM
        if(IGemFactory(gemFactory).ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        // Ensure the price is greater than zero
        if(_price == 0) {
            revert WrongPrice();
        }
        // Ensure the GEM is not already locked or being mined
        if(IGemFactory(gemFactory).isTokenLocked(_tokenId) == true) {
            revert GemIsAlreadyForSaleOrIsMining();
        }   

        // Lock the GEM and list it for sale
        GemFactory(gemFactory).setIsLocked(_tokenId, true);
        gemsForSale[_tokenId] = Sale({
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        
        // Emit an event for the GEM being listed for sale
        emit GemForSale(_tokenId, msg.sender, _price);
        return true;
    }
    
    /**
     * @notice Internal function to handle the purchase of a GEM.
     * @param _tokenId The ID of the token to be transferred.
     * @param _payer Address of the payer.
     * @param _paymentMethod The payment method used.
     * @return bool Returns true if the operation is successful.
     * @dev This function handles payment processing and GEM transfer.
     */
    function _buyGem(uint256 _tokenId, address _payer, bool _paymentMethod) internal nonReentrant returns(bool) {
        // Ensure the payer address is not zero
        if(_payer == address(0)) {
            revert AddressZero();
        }
        // Ensure the GEM is currently listed for sale
        if(!gemsForSale[_tokenId].isActive) {
            revert GemIsNotForSale();
        }
        
        uint256 price = gemsForSale[_tokenId].price;
        address seller = gemsForSale[_tokenId].seller;

        // Ensure the buyer is not the seller
        if(msg.sender == seller && msg.sender == _payer) {
            revert BuyerIsSeller("Use RemoveGemFromList instead");
        }
        
        // Handle payment and transfer based on the payment method
        if (_paymentMethod) { 
            // Transfer WSTON from payer to seller    
            IERC20(wston).transferFrom(_payer, seller, price);
        } else {
            // Calculate the total price in TON (we multiply the WSTON price by the staking index)
            uint256 tonPrice = (price * stakingIndex) / DECIMALS;
            // Add the ton fees 
            uint256 totalprice = _toWAD(tonPrice + ((tonPrice * tonFeesRate) / TON_FEES_RATE_DIVIDER));
            // Transfer TON from payer to treasury
            if(msg.value < totalprice) {
                revert WrongMsgValue();
            }
            if (seller != treasury) {
                // Approve and transfer WSTON from treasury to seller
                ITreasury(treasury).approveWstonForMarketplace(price);
                IERC20(wston).transferFrom(treasury, seller, price); // 27 decimals
            }
        }

        // Mark the GEM as no longer for sale and unlock it
        gemsForSale[_tokenId].isActive = false;
        IGemFactory(gemFactory).setIsLocked(_tokenId, false);
        // Transfer GEM ownership from seller to payer
        IGemFactory(gemFactory).transferFrom(seller, _payer, _tokenId);
        IGemFactory.Gem memory gem = IGemFactory(gemFactory).getGem(_tokenId);
        uint256 gemCoolDownDueDate = gem.gemCooldownDueDate;
        
        // Emit an event for the GEM purchase
        emit GemBought(_tokenId, _payer, seller, price, gemCoolDownDueDate);
        return true;
    }

    /**
     * @dev Converts a value from RAY (27 decimals) to WAD (18 decimals).
     * @param v The value to convert.
     * @return The converted value in WAD.
     */
    function _toWAD(uint256 v) internal pure returns (uint256) {
        return v / 10 ** 9;
    }
    
    //---------------------------------------------------------------------------------------
    //-----------------------------STORAGE GETTERS-------------------------------------------
    //---------------------------------------------------------------------------------------

    function getStakingIndex() external view returns(uint256) { return stakingIndex;}
    function getTonFeesRate() external view returns(uint256) { return tonFeesRate;}
    function getGemFactoryAddress() external view returns(address) { return gemFactory;}
    function getTreasuryAddress() external view returns(address) { return treasury;}
    function getWstonAddress() external view returns(address) { return wston;}
    function getPauseStatus() external view returns(bool) { return paused;}
    function getGemForSale(uint256 _tokenId) external view returns(Sale memory) { return gemsForSale[_tokenId];}
    function getPaused() external view returns(bool) { return paused;}
}