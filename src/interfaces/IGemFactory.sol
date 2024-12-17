// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { GemFactoryStorage } from "../L2/GemFactoryStorage.sol";

interface IGemFactory {
    struct Gem {
        uint256 tokenId;  
        uint256 value; // 27 decimals
        uint256 gemCooldownDueDate; // gem cooldown before user can start mining
        uint256 randomRequestId; // store the random request (if any). it is initially set up to 0
        uint8 rarity; 
        uint8 miningTry;
        bool isLocked; // Locked if gem is listed on the marketplace
        uint8[4] quadrants; // 4 quadrants
        uint8[2] color; // id of the color
        string tokenURI; // IPFS address of the metadata file 
    }

    function startMiningGEM(uint256 _tokenId) external returns(bool);
    function cancelMining(uint256 _tokenId) external returns(bool);
    function pickMinedGEM(uint256 _tokenId) external payable returns(bool);
    function meltGEM(uint256 _tokenId) external;

    function createGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color,  
        uint8[4] memory _quadrants,
        string memory _tokenURI
    ) external  returns (uint256);

    function createGEMPool(
        GemFactoryStorage.Rarity[] memory _rarities,
        uint8[2][] memory _colors,
        uint8[4][] memory _quadrants,
        string[] memory _tokenURIs
    ) external returns (uint256[] memory);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

    function adminTransferGEM(address _to, uint256 _tokenId) external returns (bool);

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function setIsLocked(uint256 _tokenId, bool _isLocked) external;

    function ownerOf(uint256 tokenId) external view returns(address);

    function isTokenLocked(uint256 _tokenId) external view returns(bool);

    function getGemListAvailableByRarity(uint8 _rarity) external view returns (uint256, uint256[] memory);

    function availableGemsRandomPack() external view returns(bool);

    function getGemsSupplyTotalValue() external view returns(uint256 totalValue);

    function getValueBasedOnRarity(GemFactoryStorage.Rarity _rarity) external view returns(uint256 value);

    function getCommonGemsValue() external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function getGem(uint256 tokenId) external view returns (Gem memory);

}