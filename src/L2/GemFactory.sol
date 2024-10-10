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

    /**
     * @notice Pauses the contract, preventing certain actions.
     * @dev Only callable by the owner when the contract is not paused.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing actions to be performed.
     * @dev Only callable by the owner when the contract is paused.
     */
    function unpause() public onlyOwner whenNotPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the contract with the given parameters.
     * @param _coordinator Address of the randomness coordinator.
     * @param _owner Address of the contract owner.
     * @param _wston Address of the WSTON token.
     * @param _ton Address of the TON token.
     * @param _treasury Address of the treasury contract.
     */
    function initialize(
        address _coordinator,
        address _owner,
        address _wston, 
        address _ton,
        address _treasury  
    ) external initializer {
        __ERC721_init("GemSTON", "GEM");
        __DRBConsumerBase_init(_coordinator);
        __Ownable_init(_owner);
        wston = _wston;
        ton = _ton;
        treasury = _treasury;
    }

    /**
     * @notice Sets the mining periods for different gem rarities.
     * @param _RareGemsMiningPeriod Mining period for rare gems.
     * @param _UniqueGemsMiningPeriod Mining period for unique gems.
     * @param _EpicGemsMiningPeriod Mining period for epic gems.
     * @param _LegendaryGemsMiningPeriod Mining period for legendary gems.
     * @param _MythicGemsMiningPeriod Mining period for mythic gems.
     */
    function setGemsMiningPeriods(
        uint32 _RareGemsMiningPeriod,
        uint32 _UniqueGemsMiningPeriod,
        uint32 _EpicGemsMiningPeriod,
        uint32 _LegendaryGemsMiningPeriod,
        uint32 _MythicGemsMiningPeriod
    ) external onlyOwner {
        RareGemsMiningPeriod = _RareGemsMiningPeriod;
        UniqueGemsMiningPeriod = _UniqueGemsMiningPeriod;
        EpicGemsMiningPeriod = _EpicGemsMiningPeriod;
        LegendaryGemsMiningPeriod = _LegendaryGemsMiningPeriod;
        MythicGemsMiningPeriod = _MythicGemsMiningPeriod;

        emit GemsMiningPeriodModified(
            _RareGemsMiningPeriod,
            _UniqueGemsMiningPeriod,
            _EpicGemsMiningPeriod,
            _LegendaryGemsMiningPeriod,
            _MythicGemsMiningPeriod
        );
    }

    /**
     * @notice Sets the cooldown periods for different gem rarities.
     * @param _RareGemsCooldownPeriod Cooldown period for rare gems.
     * @param _UniqueGemsCooldownPeriod Cooldown period for unique gems.
     * @param _EpicGemsCooldownPeriod Cooldown period for epic gems.
     * @param _LegendaryGemsCooldownPeriod Cooldown period for legendary gems.
     * @param _MythicGemsCooldownPeriod Cooldown period for mythic gems.
     */
    function setGemsCooldownPeriods(
        uint32 _RareGemsCooldownPeriod,
        uint32 _UniqueGemsCooldownPeriod,
        uint32 _EpicGemsCooldownPeriod,
        uint32 _LegendaryGemsCooldownPeriod,
        uint32 _MythicGemsCooldownPeriod
    ) external onlyOwner {
        RareGemsCooldownPeriod = _RareGemsCooldownPeriod;
        UniqueGemsCooldownPeriod = _UniqueGemsCooldownPeriod;
        EpicGemsCooldownPeriod = _EpicGemsCooldownPeriod;
        LegendaryGemsCooldownPeriod = _LegendaryGemsCooldownPeriod;
        MythicGemsCooldownPeriod = _MythicGemsCooldownPeriod;
        
        emit GemsCoolDownPeriodModified( 
            RareGemsCooldownPeriod, 
            UniqueGemsCooldownPeriod, 
            EpicGemsCooldownPeriod, 
            LegendaryGemsCooldownPeriod, 
            MythicGemsCooldownPeriod
        );
    }

    /**
     * @notice Sets the number of mining attempts for different gem rarities.
     * @param _RareminingTry Number of mining attempts for rare gems.
     * @param _UniqueminingTry Number of mining attempts for unique gems.
     * @param _EpicminingTry Number of mining attempts for epic gems.
     * @param _LegendaryminingTry Number of mining attempts for legendary gems.
     * @param _MythicminingTry Number of mining attempts for mythic gems.
     */
    function setMiningTrys(
        uint8 _RareminingTry,
        uint8 _UniqueminingTry,
        uint8 _EpicminingTry,
        uint8 _LegendaryminingTry,
        uint8 _MythicminingTry
    ) external onlyOwner {
        RareminingTry = _RareminingTry;
        UniqueminingTry = _UniqueminingTry;
        EpicminingTry = _EpicminingTry;
        LegendaryminingTry = _LegendaryminingTry;
        MythicminingTry = _MythicminingTry;

        emit GemsMiningTryModified(
            _RareminingTry,
            _UniqueminingTry,
            _EpicminingTry,
            _LegendaryminingTry,
            _MythicminingTry
        );
    }

    /**
     * @notice Sets the value of different gem rarities.
     * @param _CommonGemsValue Value of common gems.
     * @param _RareGemsValue Value of rare gems.
     * @param _UniqueGemsValue Value of unique gems.
     * @param _EpicGemsValue Value of epic gems.
     * @param _LegendaryGemsValue Value of legendary gems.
     * @param _MythicGemsValue Value of mythic gems.
     */
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

    /**
     * @notice Sets the treasury address.
     * @param _treasury The new treasury address.
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Sets the marketplace address.
     * @param _marketplace The new marketplace address.
     */
    function setMarketPlaceAddress(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     * @notice Sets the airdrop address.
     * @param _airdrop The new airdrop address.
     */
    function setAirdrop(address _airdrop) external onlyOwner {
        airdrop = _airdrop;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice function that allow users to forge their gems. Gems must have the same rarity. 
     * Users can choose the color the forged gem will have if it respects specific conditions. 
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
        uint32 forgedGemsMiningPeriod;
        uint32 forgedGemsCooldownPeriod;
        uint8 forgedGemsminingTry;
        uint256 forgedGemsValue;

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

        // Burn the old tokens 
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
     * @dev the Gem must be Rare or above
     * @dev the cooldown period must have elapsed
     * @dev the Gem must not be locked. Therefore, it must not be listed on the marketplace 
     * @dev There must be more than 1 mining try left
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
        // modifying storage variables associated with the mining process
        Gems.startMining(userMiningToken, userMiningStartTime, msg.sender, _tokenId);
        emit GemMiningStarted(_tokenId, msg.sender, block.timestamp, Gems[_tokenId].miningTry);
        return true;
    }

    /**
     * @notice function that cancels the mining process. note that the mining attempt spent is not recovered
     * @param _tokenId the id of the token that is mining
     * @dev the user must be the owner of the token
     * @dev the user must be mining this token.
     * @dev the user must not have already called pickMinedGem function
     */
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
        // modifying storage variable associated with the mining process
        Gems.cancelMining(userMiningToken, userMiningStartTime, msg.sender, _tokenId);
        emit MiningCancelled(_tokenId, msg.sender, block.timestamp);
        return true;
    }

    /**
     * @notice Picks a mined gem after the mining period has elapsed.
     * @param _tokenId ID of the token to pick.
     * @return requestId The request ID for randomness.
     * @dev user pays msg.value and get back the excess ETH that is not spent on gas by the node
     */
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

        // calling the requestRandomness function from the consumer with the default parameters
        (uint256 directFundingCost, uint256 requestId) = requestRandomness(0, 0, CALLBACK_GAS_LIMIT);
        Gems[_tokenId].randomRequestId = requestId;

        // updating the mapping related to the request generated by the coordinator
        s_requests[requestId].tokenId = _tokenId;
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            requestCount++;
        }

        if(msg.value > directFundingCost) { // if there is ETH to refund
            (bool success, ) = msg.sender.call{value:  msg.value - directFundingCost}("");
            if(!success) {
                revert FailedToSendEthBack();
            }
            emit EthSentBack(msg.value - directFundingCost);
        }

        emit RandomGemRequested(_tokenId, Gems[_tokenId].randomRequestId);
        return requestId;
    }

    /**
     * @notice Melts a gem, converting it back to its value.
     * @param _tokenId ID of the token to melt.
     * @dev the caller get the WSTON amount inherited by the GEM. 
     * @dev the ERC721 Token is burnt 
     * @dev caller must be the token owner
     */
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
        
        uint32 _gemCooldownPeriod;
        uint32 _miningPeriod;
        uint256 _value;
        uint8 _miningTry;

        uint8 sumOfQuadrants = _quadrants[0] + _quadrants[1] + _quadrants[2] + _quadrants[3];

        if (_rarity == Rarity.COMMON) {
            require(_quadrants[0] == 1 || _quadrants[0] == 2, "Quadrant 0 must be 1 or 2 for COMMON rarity");
            require(_quadrants[1] == 1 || _quadrants[1] == 2, "Quadrant 1 must be 1 or 2 for COMMON rarity");
            require(_quadrants[2] == 1 || _quadrants[2] == 2, "Quadrant 2 must be 1 or 2 for COMMON rarity");
            require(_quadrants[3] == 1 || _quadrants[3] == 2, "Quadrant 3 must be 1 or 2 for COMMON rarity");
            require(sumOfQuadrants < 8, "2222 is RARE not COMMON");

            _gemCooldownPeriod = 0;
            _miningPeriod = 0;
            _value = CommonGemsValue;
            _miningTry = 0;
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
    
    /**
     * @notice Transfers a GEM token from one address to another.
     * @dev Overrides the ERC721 transferFrom function. The transfer is only allowed when the contract is not paused.
     *      The GEM must not be locked, and the sender and recipient must be different.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) whenNotPaused {
        if(to == from) {
            revert SameSenderAndRecipient();
        }
        if(Gems[tokenId].isLocked) {
            revert GemIsLocked();
        }

        _transferGEM(from, to, tokenId);
        super.transferFrom(from, to, tokenId);

        emit TransferGEM(from, to, tokenId);
    }

    /**
     * @notice Safely transfers a GEM token from one address to another.
     * @dev Overrides the ERC721 safeTransferFrom function. The transfer is only allowed when the contract is not paused.
     *      Checks if the recipient is a contract and if it can handle ERC721 tokens.
     * @param from The address to transfer the token from.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     * @param data Additional data with no specified format, sent in call to `to`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721Upgradeable, IERC721) whenNotPaused {
        if(to == from) {
            revert SameSenderAndRecipient();
        }
        if(Gems[tokenId].isLocked) {
            revert GemIsLocked();
        }

        _transferGEM(from, to, tokenId);
        super.transferFrom(from, to, tokenId);

        // Check if the recipient is a contract and if it can handle ERC721 tokens
        _checkOnERC721(from, to, tokenId, data);
        emit TransferGEM(from, to, tokenId);
    }

    /**
     * @notice Sets the lock status of a GEM token.
     * @dev Only callable by the marketplace or airdrop contracts.
     * @param _tokenId The ID of the token to set the lock status for.
     * @param _isLocked The lock status to set for the token.
     */
    function setIsLocked(uint256 _tokenId, bool _isLocked) external onlyMarketPlaceOrAirdrop {
        Gems[_tokenId].isLocked = _isLocked;
    }

    /**
     * @notice Adds a new color to the list of available colors.
     * @dev Only callable by the owner of the contract.
     * @param _colorName The name of the color to add.
     * @param _index1 The first index of the color.
     * @param _index2 The second index of the color.
     */
    function addColor(string memory _colorName, uint8 _index1, uint8 _index2) external onlyOwner {
        colorName[_index1][_index2] = _colorName;
        colors.push([_index1, _index2]);
        colorsCount++;

        emit ColorAdded(colorsCount, _colorName);

    }

    /**
     * @notice Sets the token URI for a specific GEM token.
     * @param tokenId The ID of the token to set the URI for.
     * @param _tokenURI The URI to set for the token.
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        _setTokenURI(tokenId, _tokenURI);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------PRIVATE/INERNAL FUNCTIONS------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Burns tokens internally.
     * @param _from Address from which tokens are burned.
     * @param _tokenIds Array of token IDs to burn.
     */
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

    // View function to check if a color exists
    function colorExists(uint8 _index1, uint8 _index2) internal view returns (bool) {
        // Check if the color name is not an empty string
        return bytes(colorName[_index1][_index2]).length > 0;
    }

    function _transferGEM(address _from, address _to, uint256 _tokenId) private {
        Gems[_tokenId].gemCooldownPeriod = block.timestamp + _getCooldownPeriod(Gems[_tokenId].rarity);
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
            Gems[_tokenId].gemCooldownPeriod = block.timestamp + _getCooldownPeriod(Gems[s_requests[requestId].tokenId].rarity);

            delete userMiningToken[ownerOf(_tokenId)][_tokenId];
            delete userMiningStartTime[ownerOf(_tokenId)][_tokenId];

            // we set mining try of the mined gem to 0 => mined gems can't mine other gems
            Gems[s_requests[requestId].chosenTokenId].miningTry = 0;

            // transferring the Gem to the requestor
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
    function _getCooldownPeriod(Rarity rarity) internal view returns (uint256) {
        if (rarity == Rarity.COMMON) return 0;
        if (rarity == Rarity.RARE) return RareGemsCooldownPeriod;
        if (rarity == Rarity.UNIQUE) return UniqueGemsCooldownPeriod;
        if (rarity == Rarity.EPIC) return EpicGemsCooldownPeriod;
        if (rarity == Rarity.LEGENDARY) return LegendaryGemsCooldownPeriod;
        if (rarity == Rarity.MYTHIC) return MythicGemsCooldownPeriod;
        revert("Invalid rarity");
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function preMintedGemsAvailable() external view returns (uint256[] memory GemsAvailable) {
        return tokensOfOwner(treasury);
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

    function getTreasuryAddress() external view returns(address) {return treasury;}
    function getTonAddress() external view returns(address) {return ton;}
    function getWstonAddress() external view returns(address) {return wston;}
    function getMarketPlaceAddress() external view returns(address) {return marketplace;}
    function getAirdropAddress() external view returns(address) {return airdrop;}
    function getCommonGemsValue() external view returns(uint256) { return CommonGemsValue;}
    function getRareGemsValue() external view returns(uint256) {return RareGemsValue;}
    function getUniqueGemsValue() external view returns(uint256) {return UniqueGemsValue;}
    function getEpicGemsValue() external view returns(uint256) {return EpicGemsValue;}
    function getLegendaryGemsValue() external view returns(uint256) {return LegendaryGemsValue;}
    function getMythicGemsValue() external view returns(uint256) {return MythicGemsValue;}
    function getRareminingTry() external view returns(uint8) { return RareminingTry;}
    function getUniqueminingTry() external view returns(uint8) { return UniqueminingTry;}
    function getEpicminingTry() external view returns(uint8) { return EpicminingTry;}
    function getLegendaryminingTry() external view returns(uint8) { return LegendaryminingTry;}
    function getMythicminingTry() external view returns(uint8) { return MythicminingTry;}
    function getRareGemsMiningPeriod() external view returns(uint32) { return RareGemsMiningPeriod;}
    function getUniqueGemsMiningPeriod() external view returns(uint32) { return UniqueGemsMiningPeriod;}
    function getEpicGemsMiningPeriod() external view returns(uint32) { return EpicGemsMiningPeriod;}
    function getLegendaryGemsMiningPeriod() external view returns(uint32) { return LegendaryGemsMiningPeriod;}
    function getMythicGemsMiningPeriod() external view returns(uint32) { return MythicGemsMiningPeriod;}
    function getRareGemsCooldownPeriod() external view returns(uint32) { return RareGemsCooldownPeriod;}
    function getUniqueGemsCooldownPeriod() external view returns(uint32) { return UniqueGemsCooldownPeriod;}
    function getEpicGemsCooldownPeriod() external view returns(uint32) { return EpicGemsCooldownPeriod;}
    function getLegendaryGemsCooldownPeriod() external view returns(uint32) { return LegendaryGemsCooldownPeriod;}
    function getMythicGemsCooldownPeriod() external view returns(uint32) { return MythicGemsCooldownPeriod;}
    function getRequestIds() external view returns(uint256[] memory) { return requestIds;}
    function getRequestCount() external view returns(uint256) { return requestCount;}
    function getOwnershipTokenCount(address _user) external view returns(uint256) { return ownershipTokenCount[_user];}
}
