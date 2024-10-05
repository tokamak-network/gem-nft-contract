// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GemFactoryStorage} from "./GemFactoryStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../proxy/ProxyStorage.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {DRBConsumerBase} from "./Randomness/DRBConsumerBase.sol";
import {IDRBCoordinator} from "../interfaces/IDRBCoordinator.sol";

import { GemLibrary } from "../libraries/GemLibrary.sol";
import { MiningLibrary } from "../libraries/MiningLibrary.sol";
import { TransferLibrary } from "../libraries/TransferLibrary.sol";
import { ForgeLibrary } from "../libraries/ForgeLibrary.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
}

/**
 * @title GemFactory
 * @dev GemFactory handles the creation of GEMs. It allows for admin to premine GEMs for the treasury contract.
 * it also allows for users to mine forge and melt GEMs.
 */
contract GemFactory is ProxyStorage, Initializable, ERC721URIStorageUpgradeable, GemFactoryStorage, OwnableUpgradeable, DRBConsumerBase, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using GemLibrary for GemFactoryStorage.Gem[];
    using MiningLibrary for GemFactoryStorage.Gem[];
    using TransferLibrary for GemFactoryStorage.Gem[];
    using ForgeLibrary for GemFactoryStorage.Gem[];

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyTreasury() {
        require(
            msg.sender == treasury,
            "function callable from treasury contract only"
        );
        _;
    }

    modifier onlyMarketPlaceOrAirdrop() {
        require(
            msg.sender == airdrop ||
            msg.sender == marketplace, 
            "function callable from the marketplace or airdrop contracts only"
        );
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenNotPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    function initialize(
        address _coordinator,
        address _owner,
        address _wston, 
        address _ton,
        address _treasury,  
        uint256 _CommonGemsValue,
        uint256 _RareGemsValue,
        uint256 _UniqueGemsValue,
        uint256 _EpicGemsValue,
        uint256 _LegendaryGemsValue,
        uint256 _MythicGemsValue
    ) external initializer {
        __ERC721_init("GemSTON", "GEM");
        emit ERC721Initialized();
        __DRBConsumerBase_init(_coordinator);
        emit DRBConsumerBaseInitialized();
        __Ownable_init(_owner);
        emit OwnableInitialized();
        wston = _wston;
        ton = _ton;
        treasury = _treasury;
        CommonGemsValue = _CommonGemsValue;
        RareGemsValue = _RareGemsValue;
        UniqueGemsValue = _UniqueGemsValue;
        EpicGemsValue = _EpicGemsValue;
        LegendaryGemsValue = _LegendaryGemsValue;
        MythicGemsValue = _MythicGemsValue;
    }

    function setGemsMiningPeriods(
        uint256 _CommonGemsMiningPeriod,
        uint256 _RareGemsMiningPeriod,
        uint256 _UniqueGemsMiningPeriod,
        uint256 _EpicGemsMiningPeriod,
        uint256 _LegendaryGemsMiningPeriod,
        uint256 _MythicGemsMiningPeriod
    ) external onlyOwner {
        CommonGemsMiningPeriod = _CommonGemsMiningPeriod;
        RareGemsMiningPeriod = _RareGemsMiningPeriod;
        UniqueGemsMiningPeriod = _UniqueGemsMiningPeriod;
        EpicGemsMiningPeriod = _EpicGemsMiningPeriod;
        LegendaryGemsMiningPeriod = _LegendaryGemsMiningPeriod;
        MythicGemsMiningPeriod = _MythicGemsMiningPeriod;

        emit GemsMiningPeriodModified(
            _CommonGemsMiningPeriod,
            _RareGemsMiningPeriod,
            _UniqueGemsMiningPeriod,
            _EpicGemsMiningPeriod,
            _LegendaryGemsMiningPeriod,
            _MythicGemsMiningPeriod
        );
    }

    function setGemsCooldownPeriods(
        uint256 _CommonGemsCooldownPeriod, 
        uint256 _RareGemsCooldownPeriod,
        uint256 _UniqueGemsCooldownPeriod,
        uint256 _EpicGemsCooldownPeriod,
        uint256 _LegendaryGemsCooldownPeriod,
        uint256 _MythicGemsCooldownPeriod
    ) external onlyOwner {
        CommonGemsCooldownPeriod = _CommonGemsCooldownPeriod;
        RareGemsCooldownPeriod = _RareGemsCooldownPeriod;
        UniqueGemsCooldownPeriod = _UniqueGemsCooldownPeriod;
        EpicGemsCooldownPeriod = _EpicGemsCooldownPeriod;
        LegendaryGemsCooldownPeriod = _LegendaryGemsCooldownPeriod;
        MythicGemsCooldownPeriod = _MythicGemsCooldownPeriod;
        
        emit GemsCoolDownPeriodModified(
            _CommonGemsCooldownPeriod, 
            RareGemsCooldownPeriod, 
            UniqueGemsCooldownPeriod, 
            EpicGemsCooldownPeriod, 
            LegendaryGemsCooldownPeriod, 
            MythicGemsCooldownPeriod
        );
    }

    function setMiningTrys(
        uint256 _CommonminingTry, 
        uint256 _RareminingTry,
        uint256 _UniqueminingTry,
        uint256 _EpicminingTry,
        uint256 _LegendaryminingTry,
        uint256 _MythicminingTry
    ) external onlyOwner {
        CommonminingTry = _CommonminingTry;
        RareminingTry = _RareminingTry;
        UniqueminingTry = _UniqueminingTry;
        EpicminingTry = _EpicminingTry;
        LegendaryminingTry = _LegendaryminingTry;
        MythicminingTry = _MythicminingTry;

        emit GemsMiningTryModified(
            _CommonminingTry,
            _RareminingTry,
            _UniqueminingTry,
            _EpicminingTry,
            _LegendaryminingTry,
            _MythicminingTry
        );
    }

    function setGemsValue(
        uint256 _CommonGemsValue,
        uint256 _RareGemsValue,
        uint256 _UniqueGemsValue,
        uint256 _EpicGemsValue,
        uint256 _LegendaryGemsValue,
        uint256 _MythicGemsValue
    ) external onlyOwner {
        CommonGemsValue = _CommonGemsValue;
        RareGemsValue = _RareGemsValue;
        UniqueGemsValue = _UniqueGemsValue;
        EpicGemsValue = _EpicGemsValue;
        LegendaryGemsValue = _LegendaryGemsValue;
        MythicGemsValue = _MythicGemsValue;

        emit GemsValueModified(
            _CommonGemsValue,
            _RareGemsValue,
            _UniqueGemsValue,
            _EpicGemsValue,
            _LegendaryGemsValue,
            _MythicGemsValue
        );
    }

    function setRandomPack(address _randomPack) external onlyOwner {
        randomPack = _randomPack;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setMarketPlaceAddress(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function setAirdrop(address _airdrop) external onlyOwner {
        airdrop = _airdrop;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice function that allow users to forge their gems. Gems must have the same rarity and
     * same stakingIndex. Users can choose the color the forged gem will have if it respects certain conditions. 
     * old gems are burnt while the new forged gem is minted.
     * @param _tokenIds array of tokens to be forged. Must respect some length depending on the rarity chosen
     * @param _rarity to check if the rarity of each token selected is the same
     * @param _color color desired of the forged gem
     */
    function forgeTokens(
        uint256[] memory _tokenIds,
        Rarity _rarity,
        uint8[2] memory _color
    ) external whenNotPaused returns (uint256 newGemId) {
        ForgeLibrary.ForgeParams memory params = ForgeLibrary.ForgeParams({
            RareGemsValue: RareGemsValue,
            UniqueGemsValue: UniqueGemsValue,
            EpicGemsValue: EpicGemsValue,
            LegendaryGemsValue: LegendaryGemsValue,
            MythicGemsValue: MythicGemsValue,
            RareGemsMiningPeriod: RareGemsMiningPeriod,
            UniqueGemsMiningPeriod: UniqueGemsMiningPeriod,
            EpicGemsMiningPeriod: EpicGemsMiningPeriod,
            LegendaryGemsMiningPeriod: LegendaryGemsMiningPeriod,
            MythicGemsMiningPeriod: MythicGemsMiningPeriod,
            RareminingTry: RareminingTry,
            UniqueminingTry: UniqueminingTry,
            EpicminingTry: EpicminingTry,
            LegendaryminingTry: LegendaryminingTry,
            MythicminingTry: MythicminingTry,
            RareGemsCooldownPeriod: RareGemsCooldownPeriod,
            UniqueGemsCooldownPeriod: UniqueGemsCooldownPeriod,
            EpicGemsCooldownPeriod: EpicGemsCooldownPeriod,
            LegendaryGemsCooldownPeriod: LegendaryGemsCooldownPeriod,
            MythicGemsCooldownPeriod: MythicGemsCooldownPeriod
        });

        uint8[4] memory forgedQuadrants;
        Rarity newRarity;
        uint256 forgedGemsValue;
        uint256 forgedGemsMiningPeriod;
        uint256 forgedGemsCooldownPeriod;
        uint256 forgedGemsminingTry;

        (newGemId, forgedQuadrants, newRarity, forgedGemsValue, forgedGemsMiningPeriod, forgedGemsCooldownPeriod, forgedGemsminingTry) = Gems.forgeTokens(
            GEMIndexToOwner,
            ownershipTokenCount,
            msg.sender,
            _tokenIds,
            _rarity,
            _color,
            params
        );
        emit GemForged(msg.sender, _tokenIds, newGemId, newRarity, forgedQuadrants, _color, forgedGemsValue);


        // Burn the old tokens{ 
        burnTokens(msg.sender, _tokenIds);
        

        // Mint the new token
        _safeMint(msg.sender, newGemId);
        _setTokenURI(newGemId, "");

        emit Created(newGemId, newRarity, _color, forgedGemsValue, forgedQuadrants, forgedGemsMiningPeriod, forgedGemsCooldownPeriod, "", msg.sender);
        return newGemId;
    }

    /**
     * @notice triggers the mining process of a gem by the function caller
     * @param _tokenId Id of the token to be mined.
     * @return true if the gem user started mining the gem
     */
    function startMiningGEM(uint256 _tokenId) external whenNotPaused returns (bool) {
        if(msg.sender == address(0)) {
            revert AddressZero();
        }
        if(ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        if(Gems[_tokenId].gemCooldownPeriod > block.timestamp) {
            revert CooldownPeriodNotElapsed();
        }
        if(Gems[_tokenId].isLocked) {
            revert GemIsLocked();
        }
        if(Gems[_tokenId].rarity == Rarity.COMMON) {
            revert WrongRarity();
        }
        if(Gems[_tokenId].miningTry == 0) {
            revert NoMiningTryLeft();
        }

        Gems.startMining(userMiningToken, userMiningStartTime, msg.sender, _tokenId);

        emit GemMiningStarted(_tokenId, msg.sender, block.timestamp, Gems[_tokenId].miningTry);
        return true;
    }

    function cancelMining(uint256 _tokenId) external whenNotPaused returns (bool) {
        if(GEMIndexToOwner[_tokenId] != msg.sender) {
            revert NotGemOwner();
        }
        if(Gems[_tokenId].isLocked != true) {
            revert GemIsNotLocked();
        }
        if(userMiningToken[msg.sender][_tokenId] != true) {
            revert NotMining();
        }
        if(Gems[_tokenId].randomRequestId != 0) {
            revert GemAlreadyPicked();
        }
        
        Gems.cancelMining(userMiningToken, userMiningStartTime, msg.sender, _tokenId);
        emit MiningCancelled(_tokenId, msg.sender, block.timestamp);
        return true;
    }

    function pickMinedGEM(uint256 _tokenId) external payable whenNotPaused nonReentrant returns (uint256) {
        if(ownerOf(_tokenId) != msg.sender) {
            revert NotGemOwner();
        }
        if(block.timestamp < userMiningStartTime[msg.sender][_tokenId] + Gems[_tokenId].miningPeriod) {
            revert MiningPeriodNotElapsed();
        }
        if(Gems[_tokenId].isLocked == false) {
            revert GemIsNotLocked();
        }
        if(userMiningToken[ownerOf(_tokenId)][_tokenId] != true) {
            revert NotMining();
        }

        uint256 requestId = requestRandomness(0, 0, CALLBACK_GAS_LIMIT);
        Gems[_tokenId].randomRequestId = requestId;

        s_requests[requestId].tokenId = _tokenId;
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            requestCount++;
        }

        emit RandomGemRequested(_tokenId, Gems[_tokenId].randomRequestId);
        return requestId;
    }

    function meltGEM(uint256 _tokenId) external whenNotPaused {
        if(msg.sender == address(0)) {
            revert AddressZero();
        }
        if(GEMIndexToOwner[_tokenId] != msg.sender) {
            revert NotGemOwner();
        }
        uint256 amount = Gems[_tokenId].value;
        Gems.burnGem(GEMIndexToOwner, ownershipTokenCount, msg.sender, _tokenId);
        // ERC721 burn function
        _burn(_tokenId);
        
        require(ITreasury(treasury).transferWSTON(msg.sender, amount), "transfer failed");

        emit GemMelted(_tokenId, msg.sender);
    }

    function burnTokens(address _from, uint256[] memory _tokenIds) internal {
        for(uint256 i = 0; i < _tokenIds.length; ++i) {
            // delete GEM from the Gems array and every other ownership/approve storage
            delete Gems[_tokenIds[i]];
            ownershipTokenCount[_from]--;
            delete GEMIndexToOwner[_tokenIds[i]];
            // ERC721 burn function
            _burn(_tokenIds[i]);
        }
    }

    /**
     * @notice Creates a premined pool of GEM based oon their attribute passed in the parameters and assigns their ownership to the contract.
     * @param _rarity The rarity of the GEM to be created.
     * @param _color The colors of the GEM to be created.
     * @param _quadrants quadrants of the GEM to be created.
     * @param _tokenURI TokenURIs of each GEM
     * @return The IDs of the newly created GEM.
     */
    function createGEM(
        Rarity _rarity,
        uint8[2] memory _color,
        uint8[4] memory _quadrants,
        string memory _tokenURI
    ) public onlyTreasury whenNotPaused returns (uint256) {
        
        if (!colorExists(_color[0], _color[1])) {
            revert ColorNotExist();
        }        
        
        uint256 _gemCooldownPeriod;
        uint256 _miningPeriod;
        uint256 _value;
        uint256 _miningTry;

        uint8 sumOfQuadrants = _quadrants[0] + _quadrants[1] + _quadrants[2] + _quadrants[3];

        if (_rarity == Rarity.COMMON) {
            require(_quadrants[0] == 1 || _quadrants[0] == 2, "Quadrant 0 must be 1 or 2 for COMMON rarity");
            require(_quadrants[1] == 1 || _quadrants[1] == 2, "Quadrant 1 must be 1 or 2 for COMMON rarity");
            require(_quadrants[2] == 1 || _quadrants[2] == 2, "Quadrant 2 must be 1 or 2 for COMMON rarity");
            require(_quadrants[3] == 1 || _quadrants[3] == 2, "Quadrant 3 must be 1 or 2 for COMMON rarity");
            require(sumOfQuadrants < 8, "2222 is RARE not COMMON");

            _gemCooldownPeriod = CommonGemsCooldownPeriod;
            _miningPeriod = CommonGemsMiningPeriod;
            _value = CommonGemsValue;
            _miningTry = CommonminingTry;
        } else if (_rarity == Rarity.RARE) {
            require(_quadrants[0] == 2 || _quadrants[0] == 3, "Quadrant 0 must be 2 or 3 for RARE rarity");
            require(_quadrants[1] == 2 || _quadrants[1] == 3, "Quadrant 1 must be 2 or 3 for RARE rarity");
            require(_quadrants[2] == 2 || _quadrants[2] == 3, "Quadrant 2 must be 2 or 3 for RARE rarity");
            require(_quadrants[3] == 2 || _quadrants[3] == 3, "Quadrant 3 must be 2 or 3 for RARE rarity");
            require(sumOfQuadrants < 12, "3333 is UNIQUE not RARE");
            
            _gemCooldownPeriod = RareGemsCooldownPeriod;
            _miningPeriod = RareGemsMiningPeriod;
            _value = RareGemsValue;
            _miningTry = RareminingTry;
        } else if (_rarity == Rarity.UNIQUE) {
            require(_quadrants[0] == 3 || _quadrants[0] == 4, "Quadrant 0 must be 3 or 4 for UNIQUE rarity");
            require(_quadrants[1] == 3 || _quadrants[1] == 4, "Quadrant 1 must be 3 or 4 for UNIQUE rarity");
            require(_quadrants[2] == 3 || _quadrants[2] == 4, "Quadrant 2 must be 3 or 4 for UNIQUE rarity");
            require(_quadrants[3] == 3 || _quadrants[3] == 4, "Quadrant 3 must be 3 or 4 for UNIQUE rarity");
            require(sumOfQuadrants < 16, "4444 is EPIC not UNIQUE");

            _gemCooldownPeriod = UniqueGemsCooldownPeriod;
            _miningPeriod = UniqueGemsMiningPeriod;
            _value = UniqueGemsValue;
            _miningTry = UniqueminingTry;
        } else if (_rarity == Rarity.EPIC) {
            require(_quadrants[0] == 4 || _quadrants[0] == 5, "Quadrant 0 must be 4 or 5 for EPIC rarity");
            require(_quadrants[1] == 4 || _quadrants[1] == 5, "Quadrant 1 must be 4 or 5 for EPIC rarity");
            require(_quadrants[2] == 4 || _quadrants[2] == 5, "Quadrant 2 must be 4 or 5 for EPIC rarity");
            require(_quadrants[3] == 4 || _quadrants[3] == 5, "Quadrant 3 must be 4 or 5 for EPIC rarity");
            require(sumOfQuadrants < 20, "5555 is LEGENDARY not EPIC");
            
            _gemCooldownPeriod = EpicGemsCooldownPeriod;
            _miningPeriod = EpicGemsMiningPeriod;
            _value = EpicGemsValue;
            _miningTry = EpicminingTry;
        } else if (_rarity == Rarity.LEGENDARY) {
            require(_quadrants[0] == 5 || _quadrants[0] == 6, "Quadrant 0 must be 5 or 6 for LEGENDARY rarity");
            require(_quadrants[1] == 5 || _quadrants[1] == 6, "Quadrant 1 must be 5 or 6 for LEGENDARY rarity");
            require(_quadrants[2] == 5 || _quadrants[2] == 6, "Quadrant 2 must be 5 or 6 for LEGENDARY rarity");
            require(_quadrants[3] == 5 || _quadrants[3] == 6, "Quadrant 3 must be 5 or 6 for LEGENDARY rarity");
            require(sumOfQuadrants < 24, "6666 is MYTHIC not LEGENDARY");

            _gemCooldownPeriod = LegendaryGemsCooldownPeriod;
            _miningPeriod = LegendaryGemsMiningPeriod;
            _value = LegendaryGemsValue;
            _miningTry = LegendaryminingTry;
        } else if (_rarity == Rarity.MYTHIC) {
            require(
                (_quadrants[0] == 6) &&
                (_quadrants[1] == 6) &&
                (_quadrants[2] == 6) &&
                (_quadrants[3] == 6),
                "All quadrants must be 6 for MYTHIC rarity"
            );
            _gemCooldownPeriod = MythicGemsCooldownPeriod;
            _miningPeriod = MythicGemsMiningPeriod;
            _value = MythicGemsValue;
            _miningTry = MythicminingTry;
        } else {
            revert("wrong Rarity");
        }

        uint256 _cooldownDueDate = block.timestamp + _gemCooldownPeriod;

        uint256 newGemId = Gems.createGem(
            GEMIndexToOwner,
            ownershipTokenCount,
            msg.sender,
            _rarity,
            _color,
            _quadrants,
            _value,
            _miningPeriod,
            _cooldownDueDate,
            _miningTry,
            _tokenURI
        );

        _safeMint(msg.sender, newGemId);
        _setTokenURI(newGemId, _tokenURI);

        emit Created(newGemId, _rarity, _color, _value, _quadrants, _miningPeriod, _cooldownDueDate, _tokenURI, msg.sender);
        return newGemId;
    }

    /**
     * @notice Creates a premined pool of GEMs based oon their attribute passed in the parameters and assigns their ownership to the contract.
     * @param _rarities rarity of each Gem
     * @param _colors The colors of the GEMs to be created.
     * @param _quadrants quadrants of the GEMs to be created.
     * @param _tokenURIs TokenURIs of each GEM
     * @return The IDs of the newly created GEMs.
     */
    function createGEMPool(
        Rarity[] memory _rarities,
        uint8[2][] memory _colors,
        uint8[4][] memory _quadrants,
        string[] memory _tokenURIs
    ) public onlyTreasury whenNotPaused returns (uint256[] memory) {

        uint256 length = _rarities.length;  // Cache the length for gas optimization
        if (length != _colors.length || length != _quadrants.length || length != _tokenURIs.length) {
            revert MismatchedArrayLengths();
        }

        uint256[] memory newGemIds = new uint256[](_rarities.length);

        for (uint256 i = 0; i < _rarities.length; ++i) {
            newGemIds[i] = createGEM(_rarities[i], _colors[i], _quadrants[i], _tokenURIs[i]);
        }

        return newGemIds;
    }
        
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) whenNotPaused {
        if(to == from) {
            revert SameSenderAndRecipient();
        }
        if(Gems[tokenId].isLocked) {
            revert GemIsLocked();
        }

        Gems.transferGem(GEMIndexToOwner, ownershipTokenCount, from, to, tokenId);
        super.transferFrom(from, to, tokenId);

        emit TransferGEM(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721Upgradeable, IERC721) whenNotPaused {

        this.transferFrom(from, to, tokenId);

        // Check if the recipient is a contract and if it can handle ERC721 tokens
        _checkOnERC721(from, to, tokenId, data);
    }

    function setIsLocked(uint256 _tokenId, bool _isLocked) external onlyMarketPlaceOrAirdrop {
        Gems[_tokenId].isLocked = _isLocked;
    }

    function addColor(string memory _colorName, uint8 _index1, uint8 _index2) external onlyOwner {
        colorName[_index1][_index2] = _colorName;
        colors.push([_index1, _index2]);
        colorsCount++;

        emit ColorAdded(colorsCount, _colorName);

    }

    function addBackgroundColor(string memory _backgroundColor) external onlyOwner {
        customBackgroundColors[customBackgroundColorsCount] = _backgroundColor;
        backgroundColors.push(_backgroundColor);
        customBackgroundColorsCount++;

        emit BackgroundColorAdded(customBackgroundColorsCount, _backgroundColor);

    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        _setTokenURI(tokenId, _tokenURI);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------PRIVATE/INERNAL FUNCTIONS------------------------------------
    //---------------------------------------------------------------------------------------

    // View function to check if a color exists
    function colorExists(uint8 _index1, uint8 _index2) internal view returns (bool) {
        // Check if the color name is not an empty string
        return bytes(colorName[_index1][_index2]).length > 0;
    }

    function _transferGEM(address _from, address _to, uint256 _tokenId) private {
        Gems[_tokenId].gemCooldownPeriod = block.timestamp + getCooldownPeriod(Gems[_tokenId].rarity);
        ownershipTokenCount[_to]++;
        GEMIndexToOwner[_tokenId] = _to;
        ownershipTokenCount[_from]--;
    }

    // Implement the abstract function from DRBConsumerBase
    function fulfillRandomWords(uint256 requestId, uint256 randomNumber) internal override {
        if(!s_requests[requestId].requested) {
            revert RequestNotMade();
        }
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = randomNumber;
        uint256 _tokenId = s_requests[requestId].tokenId;

        uint8[4] memory quadrants = Gems[s_requests[requestId].tokenId].quadrants;
        
        (uint256 gemCount, uint256[] memory tokenIds) = countGemsByQuadrant(quadrants[0], quadrants[1], quadrants[2], quadrants[3]);
        emit CountGemsByQuadrant(gemCount, tokenIds);

        if(gemCount > 0) {
            uint256 modNbGemsAvailable = (randomNumber % gemCount);
            s_requests[requestId].chosenTokenId = tokenIds[modNbGemsAvailable];

            // reset storage variable of the initial GEM
            Gems[_tokenId].isLocked = false;
            Gems[_tokenId].randomRequestId = 0;
            Gems[_tokenId].gemCooldownPeriod = block.timestamp + TransferLibrary.getCooldownPeriod(Gems[s_requests[requestId].tokenId].rarity);

            delete userMiningToken[ownerOf(_tokenId)][_tokenId];
            delete userMiningStartTime[ownerOf(_tokenId)][_tokenId];

            require(ITreasury(treasury).transferTreasuryGEMto(s_requests[requestId].requester, s_requests[requestId].chosenTokenId), "failed to transfer token");

            emit GemMiningClaimed(_tokenId, msg.sender);
        } else {
            s_requests[requestId].chosenTokenId = 0;
            emit NoGemAvailable(_tokenId);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        if(msg.sender != ownerOf(tokenId)) {
            revert NotGemOwner();
        }
        super._setTokenURI(tokenId, _tokenURI);
    }


    function _checkOnERC721(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function preMintedGemsAvailable() external view returns (uint256[] memory GemsAvailable) {
        return tokensOfOwner(treasury);
    }

    function getCooldownPeriod(Rarity rarity) internal view returns (uint256) {
        if (rarity == Rarity.COMMON) return CommonGemsCooldownPeriod;
        if (rarity == Rarity.RARE) return RareGemsCooldownPeriod;
        if (rarity == Rarity.UNIQUE) return UniqueGemsCooldownPeriod;
        if (rarity == Rarity.EPIC) return EpicGemsCooldownPeriod;
        if (rarity == Rarity.LEGENDARY) return LegendaryGemsCooldownPeriod;
        if (rarity == Rarity.MYTHIC) return MythicGemsCooldownPeriod;
        revert("Invalid rarity");
    }

    function balanceOf(address _owner) public view override(ERC721Upgradeable, IERC721) returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return GEMIndexToOwner[tokenId] != address(0);
    }

    function getGem(uint256 tokenId) public view returns (Gem memory) {
        for (uint256 i = 0; i < Gems.length; ++i) {
            if (Gems[i].tokenId == tokenId) {
                return Gems[i];
            }
        }
        revert("Gem with the specified tokenId does not exist");
    }

    function getValueBasedOnRarity(Rarity _rarity) public view returns(uint256 value) {
        if(_rarity == Rarity.COMMON) {
            value = CommonGemsValue;
        } else if(_rarity == Rarity.RARE) {
            value = RareGemsValue;
        } else if(_rarity == Rarity.UNIQUE) {
            value = UniqueGemsValue;
        } else if(_rarity == Rarity.EPIC) {
            value = EpicGemsValue;
        } else if(_rarity == Rarity.LEGENDARY) {
            value = LegendaryGemsValue;
        } else if(_rarity == Rarity.MYTHIC) {
            value = MythicGemsValue;
        } else {
            revert("wrong rarity");
        }
    }

    function isTokenLocked(uint256 _tokenId) public view returns(bool) {
        return Gems[_tokenId].isLocked;
    }

    function getRandomRequest(uint256 _requestId) external view returns(RequestStatus memory) {
        return s_requests[_requestId];
    }

    function getColorName(uint8 _index1, uint8 _index2) public view returns (string memory) {
        return colorName[_index1][_index2];
    }

    // Function to count the number of Gems from treasury where quadrants < given quadrant and return their tokenIds
    function countGemsByQuadrant(uint8 quadrant1, uint8 quadrant2, uint8 quadrant3, uint8 quadrant4) internal view returns (uint256, uint256[] memory) {
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](Gems.length);
        uint256 index = 0;
        uint8 sumOfQuadrants = quadrant1 + quadrant2 + quadrant3+ quadrant4;

        for (uint256 i = 0; i < Gems.length; ++i) {
            uint8 GemSumOfQuadrants = Gems[i].quadrants[0] + Gems[i].quadrants[1] + Gems[i].quadrants[2] + Gems[i].quadrants[3];
            if (GemSumOfQuadrants < sumOfQuadrants && 
                GEMIndexToOwner[i] == treasury &&
                !Gems[i].isLocked
            ) {
                tokenIds[index] = Gems[i].tokenId;
                unchecked{
                    index++;
                    count++;
                } 
            }
        }
        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; ++j) {
            result[j] = tokenIds[j];
        }

        return (count, result);
    }

    function getGemListAvailableForRandomPack() external view returns (uint256, uint256[] memory) {
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](Gems.length);
        uint256 index = 0;
        
        for (uint256 i = 0; i < Gems.length; ++i) {
            if (GEMIndexToOwner[i] == treasury &&
                !Gems[i].isLocked
            ) {
                tokenIds[index] = Gems[i].tokenId;
                unchecked{
                    index++;
                    count++;
                } 
            }
        }

        // Resize the array to the actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; ++j) {
            result[j] = tokenIds[j];
        }

        return (count, result);
    }

    /// @notice Returns a list of all GEM IDs assigned to an address.
    /// @param _owner The owner of GEMs.

    function tokensOfOwner(address _owner) public view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalGems = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all gems have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 gemId;

            for (gemId = 1; gemId <= totalGems; ++gemId) {
                if (GEMIndexToOwner[gemId] == _owner) {
                    result[resultIndex] = gemId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function totalSupply() public view returns (uint256) {
        return Gems.length - 1;
    }

    function getGemsSupplyTotalValue() external view returns(uint256 totalValue) {
        for (uint256 i = 0; i < Gems.length; ++i) {
            totalValue += Gems[i].value;
        }
    }

    //---------------------------------------------------------------------------------------
    //-------------------------------STORAGE GETTERS-----------------------------------------
    //---------------------------------------------------------------------------------------

    function getTreasuryAddress() external view returns(address) {
        return treasury;
    }

    function getTonAddress() external view returns(address) {
        return ton;
    }

    function getWstonAddress() external view returns(address) {
        return wston;
    }

    function getRandomPackAddress() external view returns(address) {
        return randomPack;
    }

    function getMarketPlaceAddress() external view returns(address) {
        return marketplace;
    }

    function getAirdropAddress() external view returns(address) {
        return airdrop;
    }

    function getCommonGemsValue() external view returns(uint256) {
        return CommonGemsValue;
    }

    function getRareGemsValue() external view returns(uint256) {
        return RareGemsValue;
    }

    function getUniqueGemsValue() external view returns(uint256) {
        return UniqueGemsValue;
    }

    function getEpicGemsValue() external view returns(uint256) {
        return EpicGemsValue;
    }

    function getLegendaryGemsValue() external view returns(uint256) {
        return LegendaryGemsValue;
    }

    function getMythicGemsValue() external view returns(uint256) {
        return MythicGemsValue;
    }
}
