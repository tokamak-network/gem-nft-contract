// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GemFactoryStorage} from "./GemFactoryStorage.sol";
import {AuthControlGemFactory} from "../common/AuthControlGemFactory.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../proxy/ProxyStorage.sol";

import {RNGConsumerBase} from "./RNGConsumerBase.sol";
import {ICRRRNGCoordinator} from "../interfaces/ICRRRNGCoordinator.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
}

/**
 * @title GemFactory
 * @dev GemFactory handles the creation of GEMs. It allows for admin to premine GEMs for the treasury contract.
 * it also allows for users to mine forge and melt GEMs.
 */
contract GemFactory is ERC721URIStorage, GemFactoryStorage, ProxyStorage, AuthControlGemFactory, RNGConsumerBase {

    using SafeERC20 for IERC20;

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

    modifier onlyMarketPlace() {
        require(
            msg.sender == marketplace, 
            "function callable from treasury contract only"
        );
        _;
    }

    constructor(address coordinator) ERC721("TokamakGEM", "GEM") RNGConsumerBase(coordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function pause() public onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyPauser whenNotPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Override supportsInterface to delegate to AuthControlGemFactory's implementation
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AuthControlGemFactory) returns (bool) {
        // Delegates to AuthControlGemFactory's supportsInterface which aggregates checks across ERC165 and AccessControl
        return super.supportsInterface(interfaceId);
    }

    function initialize(
        address _wston, 
        address _ton,
        address _treasury,  
        uint256 _CommonMiningFees, 
        uint256 _RareMiningFees,
        uint256 _UniqueMiningFees,
        uint256 _EpicMiningFees,
        uint256 _LegendaryMiningFees,
        uint256 _MythicMiningFees,
        uint256 _CommonGemsValue,
        uint256 _RareGemsValue,
        uint256 _UniqueGemsValue,
        uint256 _EpicGemsValue,
        uint256 _LegendaryGemsValue,
        uint256 _MythicGemsValue
    )
    external onlyOwner {
        require(wston == address(0), "titanwston already initialized");
        require(ton == address(0), "ton already initialized");
        wston = _wston;
        ton = _ton;
        treasury = _treasury;
        CommonMiningFees = _CommonMiningFees;
        RareMiningFees = _RareMiningFees;
        UniqueMiningFees = _UniqueMiningFees;
        EpicMiningFees = _EpicMiningFees;
        LegendaryMiningFees = _LegendaryMiningFees;
        MythicMiningFees = _MythicMiningFees;
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
    ) external whenNotPaused returns(uint256 newGemId) {
        
        require(msg.sender != address(0), "zero address"); 
        
        uint256 forgedGemsValue;
        uint256 forgedGemsMiningPeriod;
        uint256 forgedGemsCooldownPeriod;

        uint8 _color_0 = _color[0];
        uint8 _color_1 = _color[1];

        if(_rarity == Rarity.COMMON) {
            require(_tokenIds.length == 2, "wrong number of Gems to be forged");
            forgedGemsValue = RareGemsValue;
            forgedGemsMiningPeriod = RareGemsMiningPeriod;
            forgedGemsCooldownPeriod = RareGemsCooldownPeriod;
        } else if(_rarity == Rarity.RARE) {
            require(_tokenIds.length == 3, "wrong number of Gems to be forged");
            forgedGemsValue = UniqueGemsValue;
            forgedGemsMiningPeriod = UniqueGemsMiningPeriod;
            forgedGemsCooldownPeriod = UniqueGemsCooldownPeriod;
        } else if(_rarity == Rarity.UNIQUE) {
            require(_tokenIds.length == 4, "wrong number of Gems to be forged");
            forgedGemsValue = EpicGemsValue;
            forgedGemsMiningPeriod = EpicGemsMiningPeriod;
            forgedGemsCooldownPeriod = EpicGemsCooldownPeriod;
        } else if(_rarity == Rarity.EPIC) {
            require(_tokenIds.length == 5, "wrong number of Gems to be forged");
            forgedGemsValue = LegendaryGemsValue;
            forgedGemsMiningPeriod = LegendaryGemsMiningPeriod;
            forgedGemsCooldownPeriod = LegendaryGemsCooldownPeriod;
        } else if(_rarity == Rarity.LEGENDARY) {
            require(_tokenIds.length == 6, "wrong number of Gems to be forged");
            forgedGemsValue = MythicGemsValue;
            forgedGemsMiningPeriod = MythicGemsMiningPeriod;
            forgedGemsCooldownPeriod = MythicGemsCooldownPeriod;
        } else {
            revert("wrong rarity");
        }

        uint8[4] memory sumOfQuadrants;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(GEMIndexToOwner[_tokenIds[i]] == msg.sender);
            require(isTokenLocked(_tokenIds[i]) == false, "Gem is for sale or is mining");
            require(Gems[_tokenIds[i]].rarity == _rarity, "wrong rarity Gems");
            sumOfQuadrants[0] += Gems[_tokenIds[i]].quadrants[0];
            sumOfQuadrants[1] += Gems[_tokenIds[i]].quadrants[1];
            sumOfQuadrants[2] += Gems[_tokenIds[i]].quadrants[2];
            sumOfQuadrants[3] += Gems[_tokenIds[i]].quadrants[3];
            
            for(uint256 j = 0; j < _tokenIds.length; j++) {
                if(i != j) {
                    uint8[2] memory _color1 = Gems[_tokenIds[i]].color;
                    uint8 _color1_0 = _color1[0];
                    uint8 _color1_1 = _color1[1];
                    uint8[2] memory _color2 = Gems[_tokenIds[j]].color;
                    uint8 _color2_0 = _color2[0];
                    uint8 _color2_1 = _color2[1];
                    bool colorValidated = false;

                    if (
                        (_color1_0 == _color_0 ||
                        _color1_1 == _color_0 ||
                        _color2_0 == _color_0 ||
                        _color2_1 == _color_0) &&
                        (_color1_0 == _color_1 ||
                        _color1_1 == _color_1 ||
                        _color2_0 == _color_1 ||
                        _color2_1 == _color_1)
                    ) {
                        colorValidated = true;
                    }
                
                    require(colorValidated, "this color can't be obtained");
                }
            }

            burnToken(msg.sender, _tokenIds[i]);
        }

        sumOfQuadrants[0] %= 2;
        sumOfQuadrants[1] %= 2;
        sumOfQuadrants[2] %= 2;
        sumOfQuadrants[3] %= 2;

        uint8[4] memory forgedQuadrants;

        uint8 baseValue;
        if (_rarity == Rarity.COMMON) baseValue = 2;
        else if (_rarity == Rarity.RARE) baseValue = 3;
        else if (_rarity == Rarity.UNIQUE) baseValue = 4;
        else if (_rarity == Rarity.EPIC) baseValue = 5;
        else if (_rarity == Rarity.LEGENDARY) baseValue = 6;

        for (uint8 i = 0; i < 4; i++) {
            forgedQuadrants[i] = baseValue + sumOfQuadrants[i];
        }

        // handling the case of sumOfQuadrants = 1111
        if (
            forgedQuadrants[0] == baseValue + 1 && 
            forgedQuadrants[1] == baseValue + 1 && 
            forgedQuadrants[2] == baseValue + 1 && 
            forgedQuadrants[3] == baseValue + 1
        ) {
            forgedQuadrants[0] = baseValue;
            forgedQuadrants[1] = baseValue;
            forgedQuadrants[2] = baseValue;
            forgedQuadrants[3] = baseValue;
        }

        // Increment the rarity to the next level
        Rarity newRarity = Rarity(uint8(_rarity) + 1);

        Gem memory _Gem = Gem({
            tokenId: 0,
            rarity: newRarity,
            quadrants: forgedQuadrants,
            color: _color,
            value: forgedGemsValue,
            miningPeriod: forgedGemsMiningPeriod,
            gemCooldownPeriod: block.timestamp + forgedGemsCooldownPeriod,
            isLocked: false,
            tokenURI: "",
            randomRequestId: 0
        });
        Gems.push(_Gem);
        newGemId = Gems.length - 1;
        // Update the tokenId of the Gem in the array
        Gems[newGemId].tokenId = newGemId;

        // safe check on the token Id created
        require(newGemId == uint256(uint32(newGemId)));
        GEMIndexToOwner[newGemId] = msg.sender;
        ownershipTokenCount[msg.sender]++;
        
        // Use the ERC721 _safeMint function to handle the token creation
        _safeMint(msg.sender, newGemId);

        // Set the token URI
        _setTokenURI(newGemId, "");

        emit GemForged(_tokenIds, newGemId, newRarity, forgedQuadrants, _color, forgedGemsValue);
        return newGemId;
    }

    /**
     * @notice triggers the mining process of a gem by the function caller
     * @param _tokenId Id of the token to be mined.
     * @return true if the gem user started mining the gem
     */
    function startMiningGEM(uint256 _tokenId) external whenNotPaused payable returns(bool) {
        // safety check on the function caller
        require(msg.sender != address(0), "zero address");
        // gem must be mineable
        require(Gems[_tokenId].gemCooldownPeriod < block.timestamp, "Gem cooldown period has not elapsed");
        // token must not be listed for sale within the marketplace
        require(!Gems[_tokenId].isLocked, "Gem is listed for sale or already mining");
        // user must not be mining another gem
        require(!isUserMining[msg.sender], "user is already mining");
        // treasury must own the token
        require(GEMIndexToOwner[_tokenId] == msg.sender, "not gem owner");

        // Mining fees calculation
        uint256 miningFees;
        uint8 sumOfQuadrants = Gems[_tokenId].quadrants[0] + Gems[_tokenId].quadrants[1] + Gems[_tokenId].quadrants[2] + Gems[_tokenId].quadrants[3];
        if(sumOfQuadrants <= 8) {
            miningFees = CommonMiningFees; 
        } else if(sumOfQuadrants > 8 && sumOfQuadrants <= 12) {
            miningFees = RareMiningFees; 
        } else if (sumOfQuadrants > 12 && sumOfQuadrants <= 16) {
            miningFees = UniqueMiningFees;
        } else if (sumOfQuadrants > 16 && sumOfQuadrants <= 20) {
            miningFees = EpicMiningFees;
        } else {
            revert("Gem not allowed to Mine");
        }

        // We set isUserMining to true to prevent the same user to recall the function
        isUserMining[msg.sender] = true;
        userMiningToken[msg.sender][_tokenId] = true;
        // Store the current timestamp
        userMiningStartTime[msg.sender][_tokenId] = block.timestamp;
        tokenMiningByUser[msg.sender] = _tokenId;
        Gems[_tokenId].isLocked = true;

         // defining the random value
        //require(tx.origin == msg.sender, "caller must be EOA");
        (uint256 requestId, uint256 requestPrice) = requestRandomness(CALLBACK_GAS_LIMIT);
        require(msg.value >= requestPrice, "Not enough funds");
        
        // storing the requestId computed
        Gems[_tokenId].randomRequestId = requestId;

        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            requestCount++;
        }
        lastRequestId = requestId;
        if (msg.value > requestPrice) {
            (bool sent, ) = payable(msg.sender).call{value: msg.value - requestPrice}("");
            require(sent, "not enough funds");
        }

        emit GemMiningStarted(_tokenId, msg.sender, block.timestamp);
        return true;
    }

    function claimMinedGEM(uint256 _tokenId) external whenNotPaused returns(bool) {
        // user must be owner of token
        require(GEMIndexToOwner[_tokenId] == msg.sender, "not GEM owner");
        // GEM must have a random requestId generated when calling startMining function
        require(Gems[_tokenId].randomRequestId != 0, "no random request for this token");
        // user must be the miner
        require(userMiningToken[msg.sender][_tokenId] == true, "user is not mining this Gem");
        // user must wait until the end of the cooldown period
        require(block.timestamp > userMiningStartTime[msg.sender][_tokenId] + Gems[_tokenId].miningPeriod, "mining period has not elapsed");
        //Verify that gem was locked 
        require(Gems[_tokenId].isLocked == true, "Gems is not mining");

        // reset mining variables
        isUserMining[msg.sender] = false;
        delete userMiningToken[msg.sender][_tokenId];
        delete userMiningStartTime[msg.sender][_tokenId];
        delete tokenMiningByUser[msg.sender];
        Gems[_tokenId].isLocked = false;

        // fetch the random request Id
        uint256 requestId = Gems[_tokenId].randomRequestId;

        require(ITreasury(treasury).transferTreasuryGEMto(msg.sender, s_requests[requestId].chosenTokenId), "failed to transfer token");

        Gems[_tokenId].randomRequestId = 0;
        Gems[_tokenId].gemCooldownPeriod = block.timestamp + getCooldownPeriod(Gems[_tokenId].rarity);
        
        emit GemMiningClaimed(_tokenId, msg.sender);
        return true;

    }

    function meltGEM(uint256 _tokenId) external whenNotPaused {
        require(msg.sender != address(0), "zero address"); 
        require(GEMIndexToOwner[_tokenId] == msg.sender);
        uint256 amount = Gems[_tokenId].value;
        burnToken(msg.sender, _tokenId);
        require(ITreasury(treasury).transferWSTON(msg.sender, amount), "transfer failed");

        emit GemMelted(_tokenId, msg.sender);
    } 

    function burnToken(address _from, uint256 _tokenId) internal {
        // delete GEM from the Gems array and every other ownership/approve storage
        delete Gems[_tokenId];
        ownershipTokenCount[_from]--;
        delete GEMIndexToOwner[_tokenId];
        delete gemAllowedToAddress[_tokenId];
        delete GEMIndexToApproved[_tokenId];

        // ERC721 burn function
        _burn(_tokenId);

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
        string memory _tokenURI) 
    external onlyTreasury whenNotPaused returns (uint256) {
        
        uint256 _gemCooldownPeriod;
        uint256 _miningPeriod;
        uint256 _value;

        uint8 sumOfQuadrants = _quadrants[0] + _quadrants[1] + _quadrants[2] + _quadrants[3];

        // Ensure that if rarity is COMMON, all quadrants must be either 1 or 2
        if (_rarity == Rarity.COMMON) {
            require(
                (_quadrants[0] == 1 || _quadrants[0] == 2) &&
                (_quadrants[1] == 1 || _quadrants[1] == 2) &&
                (_quadrants[2] == 1 || _quadrants[2] == 2) &&
                (_quadrants[3] == 1 || _quadrants[3] == 2),
                "All quadrants must be 1 or 2 for COMMON rarity"
            );
            require(sumOfQuadrants < 8, "2222 is RARE not COMMON");
            _gemCooldownPeriod = CommonGemsCooldownPeriod;
            _miningPeriod = CommonGemsMiningPeriod;
            _value = CommonGemsValue;
        } else if (_rarity == Rarity.RARE) {
            require(
                (_quadrants[0] == 2 || _quadrants[0] == 3) &&
                (_quadrants[1] == 2 || _quadrants[1] == 3) &&
                (_quadrants[2] == 2 || _quadrants[2] == 3) &&
                (_quadrants[3] == 2 || _quadrants[3] == 3),
                "All quadrants must be 2 or 3 for RARE rarity"
            );
            require(sumOfQuadrants < 12, "3333 is UNIQUE not RARE");
            _gemCooldownPeriod = RareGemsCooldownPeriod;
            _miningPeriod = RareGemsMiningPeriod;
            _value = RareGemsValue;
        } else if (_rarity == Rarity.UNIQUE) {
            require(
                (_quadrants[0] == 3 || _quadrants[0] == 4) &&
                (_quadrants[1] == 3 || _quadrants[1] == 4) &&
                (_quadrants[2] == 3 || _quadrants[2] == 4) &&
                (_quadrants[3] == 3 || _quadrants[3] == 4),
                "All quadrants must be 3 or 4 for UNIQUE rarity"
            );
            require(sumOfQuadrants < 16, "4444 is EPIC not UNIQUE");
            _gemCooldownPeriod = UniqueGemsCooldownPeriod;
            _miningPeriod = UniqueGemsMiningPeriod;
            _value = UniqueGemsValue;
        } else if (_rarity == Rarity.EPIC) {
            require(
                (_quadrants[0] == 4 || _quadrants[0] == 5) &&
                (_quadrants[1] == 4 || _quadrants[1] == 5) &&
                (_quadrants[2] == 4 || _quadrants[2] == 5) &&
                (_quadrants[3] == 4 || _quadrants[3] == 5),
                "All quadrants must be 4 or 5 for EPIC rarity"
            );
            require(sumOfQuadrants < 20, "5555 is LEGENDARY not EPIC");
            _gemCooldownPeriod = EpicGemsCooldownPeriod;
            _miningPeriod = EpicGemsMiningPeriod;
            _value = EpicGemsValue;
        } else if (_rarity == Rarity.LEGENDARY) {
            require(
                (_quadrants[0] == 5 || _quadrants[0] == 6) &&
                (_quadrants[1] == 5 || _quadrants[1] == 6) &&
                (_quadrants[2] == 5 || _quadrants[2] == 6) &&
                (_quadrants[3] == 5 || _quadrants[3] == 6),
                "All quadrants must be 5 or 6 for LEGENDARY rarity"
            );
            require(sumOfQuadrants < 24, "6666 is MYTHIC not LEGENDARY");
            _gemCooldownPeriod = LegendaryGemsCooldownPeriod;
            _miningPeriod = LegendaryGemsMiningPeriod;
            _value = LegendaryGemsValue;
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
        } else {
            revert("wrong Rarity");
        }

        Gem memory _Gem = Gem({
            tokenId: 0,
            rarity: _rarity,
            quadrants: _quadrants,
            color: _color,
            value: _value,
            miningPeriod: _miningPeriod,
            gemCooldownPeriod: block.timestamp + _gemCooldownPeriod,
            isLocked: false,
            tokenURI: _tokenURI,
            randomRequestId: 0
        });
        // storage update
        Gems.push(_Gem);
        uint256 newGemId = Gems.length - 1;
        // Update the tokenId of the Gem in the array
        Gems[newGemId].tokenId = newGemId;

        // safe check on the token Id created
        require(newGemId == uint256(uint32(newGemId)));
        GEMIndexToOwner[newGemId] = msg.sender;
        ownershipTokenCount[msg.sender]++;
        
        // Use the ERC721 _safeMint function to handle the token creation
        _safeMint(msg.sender, newGemId);

        // Set the token URI
        _setTokenURI(newGemId, _tokenURI);

        emit Created(newGemId, _rarity, _color, _value, _quadrants, _miningPeriod, _gemCooldownPeriod, _tokenURI,  msg.sender);
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
    )
        external
        onlyTreasury
        whenNotPaused
        returns (uint256[] memory)
    {
        require(
            _rarities.length == _colors.length &&
            _colors.length == _quadrants.length &&
            _quadrants.length == _tokenURIs.length,
            "Input arrays must have the same length"
        );

        uint256[] memory newGemIds = new uint256[](_rarities.length);
        uint256 _gemCooldownPeriod;
        uint256 _miningPeriod;
        uint256 _value;

        for (uint256 i = 0; i < _rarities.length; i++) {

            uint8 sumOfQuadrants = _quadrants[i][0] + _quadrants[i][1] + _quadrants[i][2] + _quadrants[i][3];

            // Ensure that if rarity is COMMON, all quadrants must be either 1 or 2
            if (_rarities[i] == Rarity.COMMON) {
                require(
                    (_quadrants[i][0] == 1 || _quadrants[i][0] == 2) &&
                    (_quadrants[i][1] == 1 || _quadrants[i][1] == 2) &&
                    (_quadrants[i][2] == 1 || _quadrants[i][2] == 2) &&
                    (_quadrants[i][3] == 1 || _quadrants[i][3] == 2),
                    "All quadrants must be 1 or 2 for COMMON rarity"
                );
                require(sumOfQuadrants < 8, "2222 is RARE not COMMON");
                _gemCooldownPeriod = CommonGemsCooldownPeriod;
                _miningPeriod = CommonGemsMiningPeriod;
                _value = CommonGemsValue;
            }

            // Ensure that if rarity is RARE, all quadrants must be either 2 or 3
            if (_rarities[i] == Rarity.RARE) {
                require(
                    (_quadrants[i][0] == 2 || _quadrants[i][0] == 3) &&
                    (_quadrants[i][1] == 2 || _quadrants[i][1] == 3) &&
                    (_quadrants[i][2] == 2 || _quadrants[i][2] == 3) &&
                    (_quadrants[i][3] == 2 || _quadrants[i][3] == 3),
                    "All quadrants must be 2 or 3 for RARE rarity"
                );
                require(sumOfQuadrants < 12, "3333 is UNIQUE not RARE");
                _gemCooldownPeriod = RareGemsCooldownPeriod;
                _miningPeriod = RareGemsMiningPeriod;
                _value = RareGemsValue;
            }

            // Ensure that if rarity is UNIQUE, all quadrants must be either 3 or 4
            if (_rarities[i] == Rarity.UNIQUE) {
                require(
                    (_quadrants[i][0] == 3 || _quadrants[i][0] == 4) &&
                    (_quadrants[i][1] == 3 || _quadrants[i][1] == 4) &&
                    (_quadrants[i][2] == 3 || _quadrants[i][2] == 4) &&
                    (_quadrants[i][3] == 3 || _quadrants[i][3] == 4),
                    "All quadrants must be 3 or 4 for UNIQUE rarity"
                );
                require(sumOfQuadrants < 16, "4444 is EPIC not UNIQUE");
                _gemCooldownPeriod = UniqueGemsCooldownPeriod;
                _miningPeriod = UniqueGemsMiningPeriod;
                _value = UniqueGemsValue;
            }

            // Ensure that if rarity is EPIC, all quadrants must be either 4 or 5
            if (_rarities[i] == Rarity.EPIC) {
                require(
                    (_quadrants[i][0] == 4 || _quadrants[i][0] == 5) &&
                    (_quadrants[i][1] == 4 || _quadrants[i][1] == 5) &&
                    (_quadrants[i][2] == 4 || _quadrants[i][2] == 5) &&
                    (_quadrants[i][3] == 4 || _quadrants[i][3] == 5),
                    "All quadrants must be 4 or 5 for EPIC rarity"
                );
                require(sumOfQuadrants < 20, "5555 is LEGENDARY not EPIC");
                _gemCooldownPeriod = EpicGemsCooldownPeriod;
                _miningPeriod = EpicGemsMiningPeriod;
                _value = EpicGemsValue;
            }

            // Ensure that if rarity is LEGENDARY, all quadrants must be either 5 or 6
            if (_rarities[i] == Rarity.LEGENDARY) {
                require(
                    (_quadrants[i][0] == 5 || _quadrants[i][0] == 6) &&
                    (_quadrants[i][1] == 5 || _quadrants[i][1] == 6) &&
                    (_quadrants[i][2] == 5 || _quadrants[i][2] == 6) &&
                    (_quadrants[i][3] == 5 || _quadrants[i][3] == 6),
                    "All quadrants must be 5 or 6 for LEGENDARY rarity"
                );
                require(sumOfQuadrants < 24, "6666 is MYTHIC not LEGENDARY");
                _gemCooldownPeriod = LegendaryGemsCooldownPeriod;
                _miningPeriod = LegendaryGemsMiningPeriod;
                _value = LegendaryGemsValue;
            }

            // Ensure that if rarity is MYTHIC, all quadrants must be equal to 6
            if (_rarities[i] == Rarity.MYTHIC) {
                require(
                    (_quadrants[i][0] == 6) &&
                    (_quadrants[i][1] == 6) &&
                    (_quadrants[i][2] == 6) &&
                    (_quadrants[i][3] == 6),
                    "All quadrants must be 6 for MYTHIC rarity"
                );
                _gemCooldownPeriod = MythicGemsCooldownPeriod;
                _miningPeriod = MythicGemsMiningPeriod;
                _value = MythicGemsValue;
            }

            Gem memory _Gem = Gem({
                tokenId: 0,
                rarity: _rarities[i],
                quadrants: _quadrants[i],
                color: _colors[i],
                value: _value,
                miningPeriod: _miningPeriod,
                gemCooldownPeriod: block.timestamp + _gemCooldownPeriod,
                isLocked: false,
                tokenURI: _tokenURIs[i],
                randomRequestId: 0
            });
            Gems.push(_Gem);
            uint256 newGemId = Gems.length - 1;

            // safe check on the token Id created
            require(newGemId == uint256(uint32(newGemId)));
            _Gem.tokenId = uint32(newGemId);
            GEMIndexToOwner[newGemId] = msg.sender;
            ownershipTokenCount[msg.sender]++;

            // Use the ERC721 _safeMint function to handle the token creation
            _safeMint(msg.sender, newGemId);
            _setTokenURI(newGemId, _tokenURIs[i]);

            emit Created(newGemId, _rarities[i], _colors[i], _value, _quadrants[i], _miningPeriod, _gemCooldownPeriod, _tokenURIs[i],  msg.sender);
            newGemIds[i] = newGemId;
        }

        return newGemIds;
    }

    function transferGEM(address _to, uint256 _tokenId) external onlyTreasury whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != msg.sender);
        require(!Gems[_tokenId].isLocked, "Gem is locked");

        // You can only send your own gem.
        require(_ownsGEM(msg.sender, _tokenId));

        // storage variables update
        _transferGEM(msg.sender, _to, _tokenId);

        // Reassign ownership,
        safeTransferFrom(msg.sender, _to, _tokenId);

        emit TransferGEM(msg.sender, _to, _tokenId);
    }

    function transferGEMFrom(address _from, address _to, uint256 _tokenId) external onlyMarketPlace whenNotPaused {
        require(_exists(_tokenId), "ERC721NonexistentToken");
        require(!Gems[_tokenId].isLocked, "Gem is locked");
        require(GEMIndexToOwner[_tokenId] == _from, "Not token owner");
        require(_to != address(0), "Invalid address");

        // storage variables update
        _transferGEM(_from, _to, _tokenId);

        // Reassign ownership,
        safeTransferFrom(_from, _to, _tokenId);

        emit TransferGEM(_from, _to, _tokenId);
    }

    /**
     * @notice allow contract owner to manually send NFTs owned by Treasury
     * @param _to address to send the token
     * @param _tokenId Id related to the token to be send
     */
    function adminTransferGEM(address _to, uint256 _tokenId) external onlyOwner returns (bool) {
        require(ITreasury(treasury).transferTreasuryGEMto(_to, _tokenId), "failed to transfer token");
        return true;
    }

    function setMarketPlaceAddress(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function setApprovalForMarketplace() external whenNotPaused {
        setApprovalForAll(marketplace, true);
    }

    function setIsLocked(uint256 _tokenId, bool _isLocked) external onlyMarketPlace {
        Gems[_tokenId].isLocked = _isLocked;
    }

    function addColor(string memory _color) external onlyOwner {
        customColors[customColorsCount] = _color;
        colors.push(_color);
        customColorsCount++;

        emit ColorAdded(customColorsCount, _color);

    }

    function addBackgroundColor(string memory _backgroundColor) external onlyOwner {
        customBackgroundColors[customBackgroundColorsCount] = _backgroundColor;
        backgroundColors.push(_backgroundColor);
        customBackgroundColorsCount++;

        emit BackgroundColorAdded(customBackgroundColorsCount, _backgroundColor);

    }

    function setNumberOfSolidColors(uint8 _numberOfSolidColors) external onlyOwner {
        numberOfSolidColors = _numberOfSolidColors;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INERNAL FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------


    function _transferGEM(address _from, address _to, uint256 _tokenId) internal {
        Gems[_tokenId].gemCooldownPeriod = block.timestamp + getCooldownPeriod(Gems[_tokenId].rarity);
        ownershipTokenCount[_to]++;
        GEMIndexToOwner[_tokenId] = _to;
        ownershipTokenCount[_from]--;
        delete gemAllowedToAddress[_tokenId];
        delete GEMIndexToApproved[_tokenId];
    }

    // Implement the abstract function from RNGConsumerBase
    function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal override {
        require(s_requests[requestId].requested, "Request not made");
        address requester = s_requests[requestId].requester;
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = hashedOmegaVal;

        uint8[4] memory quadrants = Gems[tokenMiningByUser[requester]].quadrants;
        
        (uint256 gemCount, uint256[] memory tokenIds) = countGemsByQuadrant(quadrants[0], quadrants[1], quadrants[2], quadrants[3]);

        uint256 modNbGemsAvailable = (hashedOmegaVal % gemCount) + 1;
        s_requests[requestId].chosenTokenId = tokenIds[modNbGemsAvailable];
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


    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function preMintedGemsAvailable() external view returns (uint256[] memory GemsAvailable) {
        return tokensOfOwner(treasury);
    }

    function _ownsGEM(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return GEMIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return GEMIndexToApproved[_tokenId] == _claimant;
    }

    function balanceOf(address _owner) public view override(ERC721, IERC721) returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function ownerOfGEM(uint256 _tokenId) external view returns (address owner) {
        owner = GEMIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return GEMIndexToOwner[tokenId] != address(0);
    }

    function getWston() public view returns (address) {
        return wston;
    }

    function getRareMiningFees() public view returns (uint256) {
        return RareMiningFees;
    }

    function getCommonMiningFees() public view returns (uint256) {
        return CommonMiningFees;
    }

    function getUniqueMiningFees() public view returns (uint256) {
        return UniqueMiningFees;
    }

    function getTon() public view returns (address) {
        return ton;
    }

    function getTreasury() public view returns (address) {
        return treasury;
    }

    function isTokenLocked(uint256 _tokenId) public view returns(bool) {
        return Gems[_tokenId].isLocked;
    }

    function getCustomColor(uint8 _index) public view returns (string memory) {
        require(_index < customColorsCount, "Index out of bounds");
        return customColors[_index];
    }

    // Function to count the number of Gems from treasury where quadrants < given quadrant and return their tokenIds
    function countGemsByQuadrant(uint8 quadrant1, uint8 quadrant2, uint8 quadrant3, uint8 quadrant4) internal view returns (uint256, uint256[] memory) {
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](Gems.length);
        uint256 index = 0;
        uint8 sumOfQuadrants = quadrant1 + quadrant2 + quadrant3+ quadrant4;

        for (uint256 i = 0; i < Gems.length; i++) {
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
        for (uint256 j = 0; j < count; j++) {
            result[j] = tokenIds[j];
        }

        return (count, result);
    }

    // Function to get the details of a gem by its tokenId
    function getGem(uint256 _tokenId) external view returns (Gem memory) {
        require(_tokenId < Gems.length, "Gem does not exist");
        return Gems[_tokenId];
    }

    /// @notice Returns a list of all tkGEM IDs assigned to an address.
    /// @param _owner The owner whose tkGEMs we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire tkGEM)

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

            for (gemId = 1; gemId <= totalGems; gemId++) {
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

}
