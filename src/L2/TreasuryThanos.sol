// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 
import { GemFactoryStorage } from "./GemFactoryStorage.sol";
import { AuthControl } from "../common/AuthControl.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { TreasuryStorage } from "./TreasuryStorage.sol"; 
import { MarketPlaceStorage } from "./MarketPlaceStorage.sol"; 
import "../proxy/ProxyStorage.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IMarketPlace {
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external;
    function putGemForSale(uint256 _tokenId, uint256 _price) external;
    function buyGem(uint256 _tokenId, bool _paymentMethod) external payable;
    function removeGemForSale(uint256 _tokenId) external;
    function getGemForSale(uint256 _tokenId) external view returns (Sale memory);
    function getStakingIndex() external view returns(uint256);
    function getTonFeesRate() external view returns(uint256);

    struct Sale {
        address seller;
        uint256 price;
        bool isActive;
    }
}

interface IWstonSwapPool {
    function swapTONforWSTON(uint256 tonAmount) external;
}

/**
 * @title Treasury Contract for GEM and Token Management
 * @author TOKAMAK OPAL TEAM
 * @notice This contract manages the storage and transfer of GEM tokens and WSTON tokens within the ecosystem.
 * It facilitates interactions with the Gem Factory, Marketplace, Random Pack, and Airdrop contracts.
 * The contract includes functionalities for creating premined GEMs, handling token transfers, and managing sales on the marketplace.
 * @dev The contract integrates with external interfaces for GEM creation, marketplace operations, and token swaps.
 * It includes security features such as pausing operations and role-based access control.
 */
contract TreasuryThanos is ProxyStorage, IERC721Receiver, ReentrancyGuard, AuthControl, TreasuryStorage {
    using SafeERC20 for IERC20;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyMarketPlace() {
        require(msg.sender == _marketplace, "caller is not the marketplace contract");
        _;
    }

    modifier onlyWstonSwapPoolOrOwner() {
        require(msg.sender == wstonSwapPool ||
        isOwner(), "caller is not the Swapper");
        _;
    }

    modifier onlyOwnerOrRandomPackOrMarketplace() {
        require(
            msg.sender == randomPack ||
            msg.sender == _marketplace ||
            isOwner(), "caller is neither owner nor randomPack contract"
        );
        _;
    }

    modifier onlyGemFactoryOrMarketPlaceOrRandomPackOrAirdropOrOwner() {
        require(
            msg.sender == gemFactory || 
            msg.sender == _marketplace || 
            msg.sender == randomPack ||
            msg.sender == airdrop ||
            isOwner(), "caller is neither Owner nor GemFactory nor MarketPlace nor RandomPack"
        );
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @notice we implement the receive function in order to receive TON (as a native token) 
     */
    receive() external payable {}

    //---------------------------------------------------------------------------------------
    //--------------------------------INITIALIZE FUNCTIONS-----------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the Treasury contract with the given parameters.
     * @param _wston Address of the WSTON token.
     * @param _gemFactory Address of the gem factory contract.
     */
    function initialize(address _wston, address _gemFactory) external {
        require(!initialized, "already initialized");   
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gemFactory = _gemFactory;
        wston = _wston;
        initialized = true;
    }

     /**
     * @notice Sets the address of the gem factory.
     * @param _gemFactory New address of the gem factory contract.
     */
    function setGemFactory(address _gemFactory) external onlyOwnerOrAdmin {
        _checkNonAddress(gemFactory);
        gemFactory = _gemFactory;
    }

    /**
     * @notice Sets the address of the random pack contract.
     * @param _randomPack New address of the random pack contract.
     */
    function setRandomPack(address _randomPack) external onlyOwnerOrAdmin {
        _checkNonAddress(_randomPack);
        randomPack = _randomPack;
    }

    /**
     * @notice Sets the address of the marketplace contract.
     * @param marketplace New address of the marketplace contract.
     */
    function setMarketPlace(address marketplace) external onlyOwnerOrAdmin {
        _checkNonAddress(marketplace);
        _marketplace = marketplace;
    }

    /**
     * @notice Sets the address of the airdrop contract.
     * @param _airdrop New address of the airdrop contract.
     */
    function setAirdrop(address _airdrop) external onlyOwnerOrAdmin {
        _checkNonAddress(_airdrop);
        airdrop = _airdrop;
    }

    /**
     * @notice Sets the address of the WSTON swap pool.
     * @param _wstonSwapPool New address of the WSTON swap pool.
     */
    function setWstonSwapPool(address _wstonSwapPool) external onlyOwnerOrAdmin {
        _checkNonAddress(_wstonSwapPool);
        wstonSwapPool = _wstonSwapPool;
    }

    /**
     * @notice updates the wston token address
     * @param _wston New wston token address
     */
    function setWston(address _wston) external onlyOwner {
        wston = _wston;
    }

    /**
     * @notice Approves a specific operator to manage a GEM token.
     * @param operator Address of the operator.
     * @param _tokenId ID of the token to approve.
     */
    function approveGem(address operator, uint256 _tokenId) external onlyOwnerOrAdmin {
        IGemFactory(gemFactory).approve(operator, _tokenId);
    }

    /**
     * @notice Approves the marketplace to spend a specific amount of WSTON tokens.
     * @param amount Amount of WSTON tokens to approve.
     */
    function approveWstonForMarketplace(uint256 amount) external onlyMarketPlace {
        IERC20(wston).approve(_marketplace, amount);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------EXTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Transfers WSTON tokens to a specified address.
     * @param _to Address to transfer WSTON tokens to.
     * @param _amount Amount of WSTON tokens to transfer.
     * @dev only the gemFactory, MarketPlace, RandomPack, Airdrop or the Owner are authorized to transfer the funds
     * @return bool Returns true if the transfer is successful.
     */
    function transferWSTON(address _to, uint256 _amount) external onlyGemFactoryOrMarketPlaceOrRandomPackOrAirdropOrOwner nonReentrant returns(bool) {
        // check _to diffrent from address(0)
        _checkNonAddress(_to);

        // check the balance of the treasury
        uint256 contractWSTONBalance = getWSTONBalance();
        if(contractWSTONBalance < _amount) {
            revert UnsuffiscientWstonBalance();
        }

        // transfer to the recipient
        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    /**
     * @notice Transfers TON tokens to a specified address.
     * @param _to Address to transfer TON tokens to.
     * @param _amount Amount of TON tokens to transfer.
     * @dev only the owner or the admins are authorized to call the function
     * @return bool Returns true if the transfer is successful.
     */
    function transferTON(address _to, uint256 _amount) external onlyWstonSwapPoolOrOwner returns(bool) {
        // check _to diffrent from address(0)
        _checkNonAddress(_to);

        // check the balance of the treasury 
        uint256 contractTONBalance = getTONBalance();
        if(contractTONBalance < _amount) {
            revert UnsuffiscientTonBalance();
        }

        // transfer to the recipient
        (bool success,) = _to.call{value: _amount}("");
        if(!success) {
            revert FailedToSendTON();
        }
        return true;
    }

    /**
     * @notice Creates a premined GEM with specified attributes.
     * @param _rarity Rarity of the GEM.
     * @param _color Color attributes of the GEM.
     * @param _quadrants Quadrant attributes of the GEM.
     * @param _tokenURI URI of the GEM token.
     * @dev the contract must hold enough WSTON to cover the entire supply of GEMs across all owners
     * @return uint256 Returns the ID of the created GEM.
     */
    function createPreminedGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color, 
        uint8[4] memory _quadrants,  
        string memory _tokenURI
    ) external onlyOwnerOrRandomPackOrMarketplace returns (uint256) {
        // safety check for WSTON solvency
        if(getWSTONBalance() < IGemFactory(gemFactory).getGemsSupplyTotalValue() + IGemFactory(gemFactory).getValueBasedOnRarity(_rarity)) {
            revert NotEnoughWstonAvailableInTreasury();
        }

        // we create the Gem from the GemFactory
        return IGemFactory(gemFactory).createGEM(
            _rarity,
            _color,
            _quadrants,
            _tokenURI
        );
    }

    /**
     * @notice Creates a pool of premined GEMs with specified attributes.
     * @param _rarities Array of rarities for each GEM.
     * @param _colors Array of color attributes for each GEM.
     * @param _quadrants Array of quadrant attributes for each GEM.
     * @param _tokenURIs Array of URIs for each GEM token.
     * @dev the contract must hold enough WSTON to cover the entire supply of GEMs across all owners
     * @return uint256[] Returns an array of IDs for the created GEMs.
     */
    function createPreminedGEMPool(
        GemFactoryStorage.Rarity[] memory _rarities,
        uint8[2][] memory _colors,
        uint8[4][] memory _quadrants, 
        string[] memory _tokenURIs
    ) public onlyOwnerOrRandomPackOrMarketplace returns (uint256[] memory) {
        uint256 _raritiesLength = _rarities.length;
        //calculate the value of the pool of Gems to be created
        uint256 sumOfNewPoolValues;
        for (uint256 i = 0; i < _raritiesLength; ++i) {
            sumOfNewPoolValues += IGemFactory(gemFactory).getValueBasedOnRarity(_rarities[i]);
        }

        // add the value calculated to the total supply value and check that the treasury balance holds enough WSTON
        if(getWSTONBalance() < IGemFactory(gemFactory).getGemsSupplyTotalValue() + sumOfNewPoolValues) {
            revert NotEnoughWstonAvailableInTreasury();
        }

        // we create the pool from the GemFactory
        return IGemFactory(gemFactory).createGEMPool(
            _rarities,
            _colors,
            _quadrants,
            _tokenURIs
        );
    }

    /**
     * @notice Transfers a GEM from the treasury to a specified address.
     * @param _to Address to transfer the GEM to.
     * @param _tokenId ID of the GEM token to transfer.
     * @dev only the GemFactory, MarketPlace, RandomPack, Airdrop or the Owner are able to transfer Gems from the treasury
     * @return bool Returns true if the transfer is successful.
     */
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external onlyGemFactoryOrMarketPlaceOrRandomPackOrAirdropOrOwner returns(bool) {
        IGemFactory(gemFactory).transferFrom(address(this), _to, _tokenId);
        return true;
    }

    /**
     * @notice Puts a GEM for sale on the marketplace.
     * @param _tokenId ID of the GEM token to put for sale.
     * @param _price Price at which the GEM is to be sold.
     * @dev we set approval for all for gas optimization (not approving for each gem one by one)
     */
    function putGemForSale(uint256 _tokenId, uint256 _price) external onlyOwnerOrAdmin {
        if (!IGemFactory(gemFactory).isApprovedForAll(address(this), _marketplace)) {
            IGemFactory(gemFactory).setApprovalForAll(_marketplace, true);
        }
        IMarketPlace(_marketplace).putGemForSale(_tokenId, _price);
    }

    /**
     * @notice Puts a list of GEMs for sale on the marketplace.
     * @param tokenIds Array of GEM token IDs to put for sale.
     * @param prices Array of prices at which each GEM is to be sold.
     * @dev we set approval for all for gas optimization (not approving for each gem one by one)
     */
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external onlyOwnerOrAdmin {
        if (!IGemFactory(gemFactory).isApprovedForAll(address(this), _marketplace)) {
            IGemFactory(gemFactory).setApprovalForAll(_marketplace, true);
        }
        IMarketPlace(_marketplace).putGemListForSale(tokenIds, prices);
    }

    /**
     * @notice Removes a GEM from sale on the marketplace.
     * @param _tokenId ID of the GEM token to remove from sale.
     */
    function removeGemFromSale(uint256 _tokenId) external onlyOwnerOrAdmin {
        IMarketPlace(_marketplace).removeGemForSale(_tokenId);
    }

    /**
     * @notice Buys a GEM from the marketplace.
     * @param _tokenId ID of the GEM token to buy.
     * @param _paymentMethod Payment method to use for the purchase.
     */
    function buyGem(uint256 _tokenId, bool _paymentMethod) external onlyOwnerOrAdmin {
        uint256 totalprice = 0;
        if(!_paymentMethod) {
            IMarketPlace.Sale memory sale = IMarketPlace(_marketplace).getGemForSale(_tokenId);
            uint256 stakingIndex = IMarketPlace(_marketplace).getStakingIndex();
            uint256 wstonPrice = (sale.price * stakingIndex) / DECIMALS;
            uint256 tonFeesRate = IMarketPlace(_marketplace).getTonFeesRate();
            totalprice = _toWAD(wstonPrice + ((wstonPrice * tonFeesRate) / TON_FEES_RATE_DIVIDER));
            if(address(this).balance < totalprice) {
                revert NotEnoughTonAvailableInTreasury();
            }
        }
        IMarketPlace(_marketplace).buyGem{value: totalprice}(_tokenId, _paymentMethod);
    }

    /**
     * @notice Handles the receipt of an ERC721 token.
     * @return bytes4 Returns the selector of the onERC721Received function.
     */
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------INTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Checks if the provided address is a non-zero address.
     * @param account Address to check.
     */
    function _checkNonAddress(address account) internal pure {
        if(account == address(0))   revert InvalidAddress();
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
    //------------------------STORAGE GETTER / VIEW FUNCTIONS--------------------------------
    //---------------------------------------------------------------------------------------

    // Function to check the balance of TON token within the contract
    function getTONBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to check the balance of WSTON token within the contract
    function getWSTONBalance() public view returns (uint256) {
        return IERC20(wston).balanceOf(address(this));
    }

    function getGemFactoryAddress() external view returns (address) {return gemFactory;}
    function getMarketPlaceAddress() external view returns(address) {return _marketplace;}
    function getRandomPackAddress() external view returns(address) {return randomPack;}
    function getAirdropAddress() external view returns(address) {return airdrop;}
    function getWstonAddress() external view returns(address) {return wston;}
    function getSwapPoolAddress() external view returns(address) {return wstonSwapPool;}

}