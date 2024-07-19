// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MarketPlaceStorage } from "./MarketPlaceStorage.sol";
import { GemFactory } from "./GemFactory.sol";

contract MarketPlace is MarketPlaceStorage, GemFactory {
    using SafeERC20 for IERC20;

    function initialize(address _treasury, address _titanwston, address _ton, uint256 _discountRate) external {
        require(titanwston == address(0), "titanwston already initialized");
        require(ton == address(0), "ton already initialized");
        require(_discountRate < 100, "discount rate must be less than 100%");
        titanwston = _titanwston;
        ton = _ton;
        discountRate = _discountRate;
        treasury = _treasury;
    }


    /**
     * @notice to buy a GEM listed onto the marketplace
     * @param _tokenId the ID of the token to be transferred
     * @param _paymentMethod The paymentMethod used. if true, user purchases using L2 WSTON if false, user purchases using TON
     * @return true if the GEM is transferred
     */
    function buyGem(uint256 _tokenId, bool _paymentMethod) external whenNotPaused returns(bool) {
        require(_buyGem(_tokenId, msg.sender, _paymentMethod));
        return true;
    }

    function _buyGem(uint256 _tokenId, address _payer, bool _paymentMethod) internal returns(bool) {
        require(Gems[_tokenId].isForSale, "Gem not for sale");
        require(_payer != address(0), "zero address");
        
        uint256 GemValue = Gems[_tokenId].value;
        require(GemValue != 0, "wrong value");
        
        //  transfer TON or WSTON to the treasury contract
        if (_paymentMethod) {
            uint256 discountedGemValue = GemValue - ((GemValue * discountRate) / DISCOUNT_RATE_DIVIDER);     
            IERC20(titanwston).safeTransferFrom(_payer, treasury, discountedGemValue);
        } else {
            IERC20(ton).safeTransferFrom(_payer, treasury, GemValue);
        }
        // transfer NFT ownership
        transferGEM(_payer, _tokenId);
        emit GemBought(_tokenId, _payer);
        return true;
    }

    function setDiscountRate(uint256 _discountRate) external onlyOwner {
        require(_discountRate < 100, "discount rate must be less than 100%");
        discountRate = _discountRate;
        emit SetDiscountRate(_discountRate);
    }

}