// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 
import { GemFactoryStorage } from "./GemFactoryStorage.sol";
import {AuthControlGemFactory} from "../common/AuthControlGemFactory.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


interface IMarketPlace {
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external;
    function putGemForSale(uint256 _tokenId, uint256 _price) external;
    function buyGem(uint256 _tokenId, bool _paymentMethod) external;
}

interface IWstonSwapPool {
    function swapTONforWSTON(uint256 tonAmount) external;
}


contract Treasury is IERC721Receiver, ReentrancyGuard, AuthControlGemFactory {
    using SafeERC20 for IERC20;

    address internal gemFactory;
    address internal _marketplace;
    address internal wston;
    address internal ton;
    address internal wstonSwapPool;

    bool paused = false;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyGemFactoryOrMarketPlaceOrOwner() {
        require(msg.sender == gemFactory || msg.sender == _marketplace || isAdmin(msg.sender), "caller is neither GemFactory nor MarketPlace");
        _;
    }

    constructor(address _wston, address _ton, address _gemFactory) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gemFactory = _gemFactory;
        wston = _wston;
        ton = _ton;
    }


    function setGemFactory(address _gemFactory) external onlyOwner {
        require(gemFactory != address(0), "Invalid address");
        gemFactory = _gemFactory;
    }

    function setMarketPlace(address marketplace) external onlyOwner {
        require(marketplace != address(0), "Invalid address");
        _marketplace = marketplace;
    }

    function setWstonSwapPool(address _wstonSwapPool) external onlyOwner {
        require(_wstonSwapPool != address(0), "Invalid address");
        wstonSwapPool = _wstonSwapPool;
    }

    function approveGemFactory() external onlyOwner {
        require(wston != address(0), "wston address not set");
        IERC20(wston).approve(gemFactory, type(uint256).max);
    }

    function approveMarketPlace() external onlyOwner {
        require(wston != address(0), "wston address not set");
        IERC20(wston).approve(_marketplace, type(uint256).max);
    }

    function transferWSTON(address _to, uint256 _amount) external onlyGemFactoryOrMarketPlaceOrOwner nonReentrant returns(bool) {
        require(_to != address(0), "address zero");
        uint256 contractWSTONBalance = getWSTONBalance();
        require(contractWSTONBalance >= _amount, "Unsuffiscient WSTON balance");

        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    function transferTON(address _to, uint256 _amount) external onlyOwner returns(bool) {
        require(_to != address(0), "address zero");
        uint256 contractTONBalance = getTONBalance();
        require(contractTONBalance >= _amount, "Unsuffiscient TON balance");

        IERC20(ton).safeTransfer(_to, _amount);
        return true;
    }

    // @audit-issue safety checks on solvability => make sure that there is enough WSTON inside of the contract
    function createPreminedGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color, 
        uint8[4] memory _quadrants,  
        string memory _tokenURI
    ) external onlyOwner returns (uint256) {
        return IGemFactory(gemFactory).createGEM(
            _rarity,
            _color,
            _quadrants,
            _tokenURI
        );
    }

    // @audit-issue safety checks on solvability => make sure that there is enough WSTON inside of the contract
    function createPreminedGEMPool(
        GemFactoryStorage.Rarity[] memory _rarities,
        uint8[2][] memory _colors,
        uint8[4][] memory _quadrants, 
        string[] memory _tokenURIs
    ) external onlyOwner returns (uint256[] memory) {
        return IGemFactory(gemFactory).createGEMPool(
            _rarities,
            _colors,
            _quadrants,
            _tokenURIs
        );
    }

    function transferTreasuryGEMto(address _to, uint256 _tokenId) external onlyGemFactoryOrMarketPlaceOrOwner returns(bool) {
        IGemFactory(gemFactory).transferFrom(address(this), _to, _tokenId);
        return true;
    }

    function putGemForSale(uint256 _tokenId, uint256 _price) external onlyOwner {
        IMarketPlace(_marketplace).putGemForSale(_tokenId, _price);
    }

    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external onlyOwner {
        IMarketPlace(_marketplace).putGemListForSale(tokenIds, prices);
    }

    function buyGem(uint256 _tokenId, bool _paymentMethod) external onlyOwner {
        IMarketPlace(_marketplace).buyGem(_tokenId, _paymentMethod);
    }

    function swapTONforWSTON(uint256 tonAmount) external onlyOwner {
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
    
}