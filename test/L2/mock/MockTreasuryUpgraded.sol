// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGemFactory } from "../../../src/interfaces/IGemFactory.sol"; 
import { GemFactoryStorage } from "../../../src/L2/GemFactoryStorage.sol";
import {AuthControl} from "../../../src/common/AuthControl.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { TreasuryStorage } from "../../../src/L2/TreasuryStorage.sol"; 
import "../../../src/proxy/ProxyStorage.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


interface IMarketPlace {
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external;
    function putGemForSale(uint256 _tokenId, uint256 _price) external;
    function buyGem(uint256 _tokenId, bool _paymentMethod) external;
    function removeGemForSale(uint256 _tokenId) external;
}

interface IWstonSwapPool {
    function swapTONforWSTON(uint256 tonAmount) external;
}


contract MockTreasuryUpgraded is ProxyStorage, IERC721Receiver, ReentrancyGuard, AuthControl, TreasuryStorage {
    // new variable
    uint256 public counter;


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
        require(msg.sender == _marketplace, "caller is  not the marketplace contract");
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

    function initialize(address _wston, address _ton, address _gemFactory) external {
        require(!initialized, "already initialized");   
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gemFactory = _gemFactory;
        wston = _wston;
        ton = _ton;
        initialized = true;
    }


    function setGemFactory(address _gemFactory) external onlyOwnerOrAdmin {
        _checkNonAddress(gemFactory);
        gemFactory = _gemFactory;
    }

    function setRandomPack(address _randomPack) external onlyOwnerOrAdmin {
        _checkNonAddress(_randomPack);
        randomPack = _randomPack;
    }

    function setMarketPlace(address marketplace) external onlyOwnerOrAdmin {
        _checkNonAddress(marketplace);
        _marketplace = marketplace;
    }

    function setAirdrop(address _airdrop) external onlyOwnerOrAdmin {
        _checkNonAddress(_airdrop);
        airdrop = _airdrop;
    }

    function setWstonSwapPool(address _wstonSwapPool) external onlyOwnerOrAdmin {
        _checkNonAddress(_wstonSwapPool);
        wstonSwapPool = _wstonSwapPool;
    }

    function approveGemFactory() external onlyOwnerOrAdmin {
        _checkNonAddress(wston);
        IERC20(wston).approve(gemFactory, type(uint256).max);
    }

    function wstonApproveMarketPlace() external onlyOwnerOrAdmin {
        _checkNonAddress(wston);
        IERC20(wston).approve(_marketplace, type(uint256).max);
    }

    function tonApproveMarketPlace() external onlyOwnerOrAdmin {
        _checkNonAddress(ton);
        IERC20(ton).approve(_marketplace, type(uint256).max);
    }

    function tonApproveWstonSwapPool() external onlyOwnerOrAdmin {
        _checkNonAddress(ton);
        IERC20(ton).approve(wstonSwapPool, type(uint256).max);
    }

    function approveGem(address operator, uint256 _tokenId) external onlyOwnerOrAdmin {
        IGemFactory(gemFactory).approve(operator, _tokenId);
    }

    function approveWstonForMarketplace(uint256 amount) external onlyMarketPlace {
        IERC20(wston).approve(_marketplace, amount);
    }

    function transferWSTON(address _to, uint256 _amount) external onlyGemFactoryOrMarketPlaceOrRandomPackOrAirdropOrOwner nonReentrant returns(bool) {
        
        _checkNonAddress(_to);

        uint256 contractWSTONBalance = getWSTONBalance();
        if(contractWSTONBalance < _amount) {
            revert UnsuffiscientWstonBalance();
        }

        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    function transferTON(address _to, uint256 _amount) external onlyOwnerOrAdmin returns(bool) {
        _checkNonAddress(_to);   
        uint256 contractTONBalance = getTONBalance();
        if(contractTONBalance < _amount) {
            revert UnsuffiscientTonBalance();
        }
        IERC20(ton).safeTransfer(_to, _amount);
        return true;
    }

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

        return IGemFactory(gemFactory).createGEM(
            _rarity,
            _color,
            _quadrants,
            _tokenURI
        );
    }

    function createPreminedGEMPool(
        GemFactoryStorage.Rarity[] memory _rarities,
        uint8[2][] memory _colors,
        uint8[4][] memory _quadrants, 
        string[] memory _tokenURIs
    ) public onlyOwnerOrRandomPackOrMarketplace returns (uint256[] memory) {
        uint256 sumOfNewPoolValues;
        for (uint256 i = 0; i < _rarities.length; ++i) {
            sumOfNewPoolValues += IGemFactory(gemFactory).getValueBasedOnRarity(_rarities[i]);
        }
        if(getWSTONBalance() < IGemFactory(gemFactory).getGemsSupplyTotalValue() + sumOfNewPoolValues) {
            revert NotEnoughWstonAvailableInTreasury();
        }

        return IGemFactory(gemFactory).createGEMPool(
            _rarities,
            _colors,
            _quadrants,
            _tokenURIs
        );
    }

    function transferTreasuryGEMto(address _to, uint256 _tokenId) external onlyGemFactoryOrMarketPlaceOrRandomPackOrAirdropOrOwner returns(bool) {
        IGemFactory(gemFactory).transferFrom(address(this), _to, _tokenId);
        return true;
    }

    function putGemForSale(uint256 _tokenId, uint256 _price) external onlyOwnerOrAdmin {
        if (!IGemFactory(gemFactory).isApprovedForAll(address(this), _marketplace)) {
            IGemFactory(gemFactory).setApprovalForAll(_marketplace, true);
        }
        IMarketPlace(_marketplace).putGemForSale(_tokenId, _price);
    }

    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external onlyOwnerOrAdmin {
        if (!IGemFactory(gemFactory).isApprovedForAll(address(this), _marketplace)) {
            IGemFactory(gemFactory).setApprovalForAll(_marketplace, true);
        }
        IMarketPlace(_marketplace).putGemListForSale(tokenIds, prices);
    }

    function removeGemFromSale(uint256 _tokenId) external onlyOwnerOrAdmin {
        IMarketPlace(_marketplace).removeGemForSale(_tokenId);
    }

    function buyGem(uint256 _tokenId, bool _paymentMethod) external onlyOwnerOrAdmin {
        IMarketPlace(_marketplace).buyGem(_tokenId, _paymentMethod);
    }

    function swapTONforWSTON(uint256 tonAmount) external onlyOwnerOrAdmin {
        IWstonSwapPool(wstonSwapPool).swapTONforWSTON(tonAmount);
    }

    // onERC721Received function to accept ERC721 tokens
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _checkNonAddress(address account) internal pure {
        if(account == address(0))   revert InvalidAddress();
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    // Function to check the balance of TON token within the contract
    function getTONBalance() public view returns (uint256) {
        return IERC20(ton).balanceOf(address(this));
    }

    // Function to check the balance of WSTON token within the contract
    function getWSTONBalance() public view returns (uint256) {
        return IERC20(wston).balanceOf(address(this));
    }

    function getGemFactoryAddress() public view returns (address) {
        return gemFactory;
    }

    function getRandomPackAddress() public view returns(address) {
        return randomPack;
    }

    function getCounter() external view returns(uint256) {
        return counter;
    }

    function incrementCounter() external {
        counter++;
    }
     
}