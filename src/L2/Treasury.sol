// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol"; 
import { GemFactoryStorage } from "./GemFactoryStorage.sol";
import {AuthControl} from "../common/AuthControl.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


interface IMarketPlace {
    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external;
    function putGemForSale(uint256 _tokenId, uint256 _price) external;
    function buyGem(uint256 _tokenId, bool _paymentMethod) external;
    function removeGemForSale(uint256 _tokenId) external;
}

interface IWstonSwapPool {
    function swapTONforWSTON(uint256 tonAmount) external;
}


contract Treasury is IERC721Receiver, ReentrancyGuard, AuthControl {
    using SafeERC20 for IERC20;

    address internal gemFactory;
    address internal _marketplace;
    address internal randomPack;
    address internal wston;
    address internal ton;
    address internal wstonSwapPool;

    bool paused = false;
    string public commonGemTokenUri;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyOwnerOrRandomPack() {
        require(
            msg.sender == randomPack ||
            isOwner(), "caller is neither owner nor randomPack contract"
        );
        _;
    }

    modifier onlyGemFactoryOrMarketPlaceOrRandomPackOrOwner() {
        require(
            msg.sender == gemFactory || 
            msg.sender == _marketplace || 
            msg.sender == randomPack ||
            isOwner(), "caller is neither Owner nor GemFactory nor MarketPlace nor RandomPack"
        );
        _;
    }

    constructor(address _wston, address _ton, address _gemFactory) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        gemFactory = _gemFactory;
        wston = _wston;
        ton = _ton;
        commonGemTokenUri = "";
    }


    function setGemFactory(address _gemFactory) external onlyOwner {
        require(gemFactory != address(0), "Invalid address");
        gemFactory = _gemFactory;
    }

    function setRandomPack(address _randomPack) external onlyOwner {
        require(_randomPack != address(0), "Invalid address");
        randomPack = _randomPack;
    }

    function setMarketPlace(address marketplace) external onlyOwner {
        require(marketplace != address(0), "Invalid address");
        _marketplace = marketplace;
    }

    function setWstonSwapPool(address _wstonSwapPool) external onlyOwner {
        require(_wstonSwapPool != address(0), "Invalid address");
        wstonSwapPool = _wstonSwapPool;
    }

    function setCommonGemTokenUri(string memory _tokenURI) external onlyOwner {
        commonGemTokenUri = _tokenURI;
    }

    function approveGemFactory() external onlyOwner {
        require(wston != address(0), "wston address not set");
        IERC20(wston).approve(gemFactory, type(uint256).max);
    }

    function wstonApproveMarketPlace() external onlyOwner {
        require(wston != address(0), "wston address not set");
        IERC20(wston).approve(_marketplace, type(uint256).max);
    }

    function tonApproveMarketPlace() external onlyOwner {
        require(ton != address(0), "wston address not set");
        IERC20(ton).approve(_marketplace, type(uint256).max);
    }

    function tonApproveWstonSwapPool() external onlyOwner {
        require(ton != address(0), "wston address not set");
        IERC20(ton).approve(wstonSwapPool, type(uint256).max);
    }

    function transferWSTON(address _to, uint256 _amount) external onlyGemFactoryOrMarketPlaceOrRandomPackOrOwner nonReentrant returns(bool) {
        require(_to != address(0), "address zero");
        uint256 contractWSTONBalance = getWSTONBalance();
        require(contractWSTONBalance >= _amount, "Unsuffiscient WSTON balance");

        IERC20(wston).safeTransfer(_to, _amount);
        return true;
    }

    function transferTON(address _to, uint256 _amount) external onlyOwnerOrAdmin returns(bool) {
        require(_to != address(0), "address zero");
        uint256 contractTONBalance = getTONBalance();
        require(contractTONBalance >= _amount, "Unsuffiscient TON balance");

        IERC20(ton).safeTransfer(_to, _amount);
        return true;
    }

    function createPreminedGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color, 
        uint8[4] memory _quadrants,  
        string memory _tokenURI
    ) public onlyOwnerOrRandomPack returns (uint256) {
        // safety check for WSTON solvency
        require(
            getWSTONBalance() >= IGemFactory(gemFactory).getGemsSupplyTotalValue() + IGemFactory(gemFactory).getValueBasedOnRarity(_rarity),
            "Not enough WSTON available in Treasury"
        );
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
    ) public onlyOwnerOrRandomPack returns (uint256[] memory) {
        uint256 sumOfNewPoolValues;
        for (uint256 i = 0; i < _rarities.length; i++) {
        sumOfNewPoolValues += IGemFactory(gemFactory).getValueBasedOnRarity(_rarities[i]);
        }

        require(
            getWSTONBalance() >= IGemFactory(gemFactory).getGemsSupplyTotalValue() + sumOfNewPoolValues,
            "Not enough WSTON available in Treasury"
        );

        return IGemFactory(gemFactory).createGEMPool(
            _rarities,
            _colors,
            _quadrants,
            _tokenURIs
        );
    }

    function transferTreasuryGEMto(address _to, uint256 _tokenId) external onlyGemFactoryOrMarketPlaceOrRandomPackOrOwner returns(bool) {
        IGemFactory(gemFactory).transferFrom(address(this), _to, _tokenId);
        return true;
    }

    function putGemForSale(uint256 _tokenId, uint256 _price) external onlyOwnerOrAdmin {
        IMarketPlace(_marketplace).putGemForSale(_tokenId, _price);
    }

    function putGemListForSale(uint256[] memory tokenIds, uint256[] memory prices) external onlyOwnerOrAdmin {
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


    function buyCommonGem() external whenNotPaused returns(uint256 newTokenId) {
        // we fetch the value of a common gem
        uint256 commonGemValue = IGemFactory(gemFactory).getCommonValue();
        // the function caller pays a WSTON amount equal to the value of the GEM.
        IERC20(wston).safeTransferFrom(msg.sender, address(this), commonGemValue);
        // we mint from scratch a perfect common GEM 
        newTokenId = createPreminedGEM(GemFactoryStorage.Rarity.COMMON, [0,0], [1,1,1,1], commonGemTokenUri);
        // the new gem is transferred to the user
        IGemFactory(gemFactory).transferFrom(address(this), msg.sender, newTokenId);
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

    function getRandomPackAddress() public view returns(address) {
        return randomPack;
    }
    
}