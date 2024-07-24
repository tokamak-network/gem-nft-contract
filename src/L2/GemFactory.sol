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
        address _titanwston, 
        address _ton,
        address _treasury,
        address _marketplace,  
        uint256 _CommonMiningFees, 
        uint256 _RareMiningFees,
        uint256 _UniqueMiningFees
    )
    external {
        require(wston == address(0), "titanwston already initialized");
        require(ton == address(0), "ton already initialized");
        wston = _titanwston;
        ton = _ton;
        treasury = _treasury;
        marketplace = _marketplace;
        CommonMiningFees = _CommonMiningFees;
        RareMiningFees = _RareMiningFees;
        UniqueMiningFees = _UniqueMiningFees;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------


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
        require(GEMIndexToOwner[_tokenId] == msg.sender);

        // Mining fees calculation
        uint256 miningFees;
        if(Gems[_tokenId].quadrants < 0x0F) {
            miningFees = CommonMiningFees; 
        } else if(Gems[_tokenId].quadrants >= 0x0F && Gems[_tokenId].quadrants < 0x1E) {
            miningFees = RareMiningFees; 
        } else if (Gems[_tokenId].quadrants >= 0x1E && Gems[_tokenId].quadrants < 0x2D) {
            miningFees = UniqueMiningFees;
        } else {
            revert("Gem not allowed to Mine");
        }

        // User pays mining fees
        IERC20(ton).safeTransferFrom(msg.sender, treasury, miningFees);

        // We set isUserMining to true to prevent the same user to recall the function
        isUserMining[msg.sender] = true;
        userMiningToken[msg.sender][_tokenId] = true;
        // Store the current timestamp
        userMiningStartTime[msg.sender][_tokenId] = block.timestamp;
        tokenMiningByUser[msg.sender] = _tokenId;
        Gems[_tokenId].isLocked = true;

         // defining the random value
        require(tx.origin == msg.sender, "caller must be EOA");
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

        emit GemMiningStarted(_tokenId, msg.sender);
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


    function createGEM( 
        string memory _color, 
        uint256 _value, 
        bytes1 _quadrants, 
        string memory _backgroundColor,
        uint256 _miningPeriod,
        uint256 _gemCooldownPeriod,
        string memory _tokenURI) 
    external onlyTreasury whenNotPaused returns (uint256) {
        Gem memory _Gem = Gem({
            tokenId: 0,
            quadrants: _quadrants,
            color: _color,
            value: _value,
            backgroundColor: _backgroundColor,
            miningPeriod: _miningPeriod,
            gemCooldownPeriod: block.timestamp + _gemCooldownPeriod,
            isLocked: false,
            tokenURI: _tokenURI,
            randomRequestId: 0
        });
        // storage update
        Gems.push(_Gem);
        uint256 newGemId = Gems.length - 1;

        // safe check on the token Id created
        require(newGemId == uint256(uint32(newGemId)));
        _Gem.tokenId = uint32(newGemId);
        GEMIndexToOwner[newGemId] = msg.sender;
        ownershipTokenCount[msg.sender]++;
        
        // Use the ERC721 _safeMint function to handle the token creation
        _safeMint(msg.sender, newGemId);

        // Set the token URI
        _setTokenURI(newGemId, _tokenURI);

        emit Created(newGemId, _quadrants, _color, _value, msg.sender);
        return newGemId;
    }

    function transferGEM(address _to, uint256 _tokenId) external onlyTreasury whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != msg.sender);

        // You can only send your own gem.
        require(_ownsGEM(msg.sender, _tokenId));

        // storage variables update
        _transferGEM(msg.sender, _to, _tokenId);

        // Reassign ownership,
        safeTransferFrom(msg.sender, _to, _tokenId);

        emit TransferGEM(msg.sender, _to, _tokenId);
    }

    function transferGEMFrom(address _from, address _to, uint256 _tokenId) external onlyMarketPlace whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != msg.sender);

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

    /**
     * @notice Creates a premined pool of GEMs based oon their attribute passed in the parameters and assigns their ownership to the contract.
     * @param _colors The colors of the GEMs to be created.
     * @param _values The values of the GEMs to be created.
     * @param _quadrants The quadrants of the GEMs to be created.
     * @param _miningPeriod period in seconds that a user have to wait for claiming a mined gem  
     * @param _gemCooldownPeriod period in second that a user must wait before using it for mining
     * @return The IDs of the newly created GEMs.
     */
    // generic data to use for events
    // consider gem are not forgeable => implement cooldown
    function createGEMPool(
        string[] memory _colors,
        uint256[] memory _values,
        bytes1[] memory _quadrants,
        string[]memory _backgroundColor,
        uint256[] memory _miningPeriod,
        uint256[] memory _gemCooldownPeriod,
        string[] memory _tokenURIs
    ) external onlyTreasury whenNotPaused returns (uint256[] memory) {
        require(
            _colors.length == _values.length &&
            _values.length == _quadrants.length &&
            _quadrants.length == _miningPeriod.length &&
            _miningPeriod.length == _gemCooldownPeriod.length &&
            _gemCooldownPeriod.length == _tokenURIs.length,
            "Input arrays must have the same length"
        );

        uint256[] memory newGemIds = new uint256[](_values.length);

        for (uint256 i = 0; i < _values.length; i++) {
            Gem memory _Gem = Gem({
                tokenId: 0,
                quadrants: _quadrants[i],
                color: _colors[i],
                value: _values[i],
                backgroundColor: _backgroundColor[i],
                miningPeriod: _miningPeriod[i],
                gemCooldownPeriod: block.timestamp + _gemCooldownPeriod[i],
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

            emit Created(newGemId, _quadrants[i], _colors[i], _values[i], msg.sender);
            newGemIds[i] = newGemId;
        }

        return newGemIds;
    }


    //---------------------------------------------------------------------------------------
    //--------------------------INERNAL FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------


    function _transferGEM(address _from, address _to, uint256 _tokenId) internal {
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

        bytes1 quadrant = Gems[tokenMiningByUser[requester]].quadrants;
        
        (uint256 gemCount, uint256[] memory tokenIds) = countGemsByQuadrant(quadrant);

        uint256 modNbGemsAvailable = (hashedOmegaVal % gemCount) + 1;
        s_requests[requestId].chosenTokenId = tokenIds[modNbGemsAvailable];
        require(ITreasury(treasury).transferTreasuryGEMto(requester, s_requests[requestId].chosenTokenId), "failed to transfer token");
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

    // Function to count the number of Gems from treasury where quadrants < given quadrant and return their tokenIds
    function countGemsByQuadrant(bytes2 quadrant) internal view returns (uint256, uint256[] memory) {
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](Gems.length);
        uint256 index = 0;

        for (uint256 i = 0; i < Gems.length; i++) {
            if (Gems[i].quadrants < quadrant && GEMIndexToOwner[i] == treasury) {
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
