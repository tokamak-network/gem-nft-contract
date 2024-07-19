// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GemFactoryStorage} from "./GemFactoryStorage.sol";
import {AuthControlGemFactory} from "../common/AuthControlGemFactory.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../proxy/ProxyStorage.sol";

/**
 * @title GemFactory
 * @dev GemFactory handles the creation of GEMs. It allows for admin to premine GEMs for the treasury contract.
 * it also allows for users to mine forge and melt GEMs.
 */
contract GemFactory is ERC721, GemFactoryStorage, ProxyStorage, AuthControlGemFactory {

    using SafeERC20 for IERC20;

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor() ERC721("TokamakGEM", "GEM") {}

    // Override supportsInterface to delegate to AuthControlGemFactory's implementation
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AuthControlGemFactory) returns (bool) {
        // Delegates to AuthControlGemFactory's supportsInterface which aggregates checks across ERC165 and AccessControl
        return super.supportsInterface(interfaceId);
    }

    function initialize(
        address _titanwston, 
        address _ton,
        address _treasury, 
        uint256 _miningCooldown, 
        uint256 _BaseMiningFees, 
        uint256 _CommonMiningFees, 
        uint256 _UncommonMiningFees,
        uint256 _RareMiningFees)
    external {
        require(titanwston == address(0), "titanwston already initialized");
        require(ton == address(0), "ton already initialized");
        require(_miningCooldown != 0, "mining cooldown must be greater than 0");
        titanwston = _titanwston;
        ton = _ton;
        treasury = _treasury;
        miningCooldown = _miningCooldown;
        BaseMiningFees = _BaseMiningFees;
        CommonMiningFees = _CommonMiningFees;
        UncommonMiningFees = _UncommonMiningFees;
        RareMiningFees = _RareMiningFees;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------


    /**
     * @notice triggers the mining process of a gem by the function caller
     * @param _tokenId Id of the token to be mined.
     * @return true if the gem user started mining the gem
     */
    function startMiningGem(uint256 _tokenId) external whenNotPaused returns(bool) {
        require(_tokenId != 0, "tokenId must be different from 0");
        // safety check on the function caller
        require(msg.sender != address(0), "zero address");
        // gem must be mineable
        require(Gems[_tokenId].isMinable && Gems[_tokenId].cooldownPeriod != 0, "Gem can not be mined");
        // token must not be listed for sale within the marketplace
        require(!Gems[_tokenId].isForSale, "Gem is listed for sale");
        // user must not be mining another gem
        require(!isUserMining[msg.sender], "user is already mining");
        // treasury must own the token
        require(GEMIndexToOwner[_tokenId] == address(this));

        // Mining fees calculation
        uint256 miningFees;
        if(Gems[_tokenId].rarity == Rarity.BASE) {
            miningFees = BaseMiningFees; 
        } else if(Gems[_tokenId].rarity == Rarity.COMMON) {
            miningFees = CommonMiningFees; 
        } else if(Gems[_tokenId].rarity == Rarity.UNCOMMON) {
            miningFees = UncommonMiningFees; 
        } else if(Gems[_tokenId].rarity == Rarity.RARE) {
            miningFees = RareMiningFees; 
        }

        // User pays mining fees
        IERC20(ton).safeTransferFrom(msg.sender, treasury, miningFees);

        Gems[_tokenId].isMinable = false;
        // We set isUserMining to true to prevent the same user to recall the function
        isUserMining[msg.sender] = true;
        userMiningToken[msg.sender][_tokenId] = true;
        // Store the current timestamp
        userMiningStartTime[msg.sender][_tokenId] = block.timestamp;

        emit GemMining(_tokenId, msg.sender);
        return true;
    }

    function claimMinedGem(uint256 _tokenId) external whenNotPaused returns(bool) {
        // user must be the miner
        require(userMiningToken[msg.sender][_tokenId] == true, "user is not mining this Gem");
        // user must wait until the end of the cooldown period
        require(block.timestamp > (userMiningStartTime[msg.sender][_tokenId] + Gems[_tokenId].cooldownPeriod), "cooldown period has not elapsed");

        // reset mining variables
        isUserMining[msg.sender] = false;
        delete userMiningToken[msg.sender][_tokenId];
        delete userMiningStartTime[msg.sender][_tokenId];

        // transfer ownership of the gem to user
        transferGEM(msg.sender, _tokenId);

        emit GemMiningClaimed(_tokenId, msg.sender);
        return true;

    }


    function createGEM( 
        Rarity _rarity, 
        string memory _color, 
        uint256 _value, 
        bytes4 _quadrants, 
        string memory _colorStyle,
        string memory _backgroundColor,
        string memory _backgroundColorStyle,
        uint256 _cooldownPeriod) 
    external onlyTreasuryOrAdmin whenNotPaused returns (uint256) {
        Gem memory _Gem = Gem({
            tokenId: 0,
            rarity: _rarity,
            quadrants: _quadrants,
            color: _color,
            value: _value,
            colorStyle: _colorStyle,
            backgroundColor: _backgroundColor,
            backgroundColorStyle: _backgroundColorStyle,
            cooldownPeriod: _cooldownPeriod,
            isMinable: false,
            isForSale: false
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

        emit Created(newGemId, _rarity, _quadrants, _color, _value, msg.sender);
        return newGemId;
    }

    function transferGEM(address _to, uint256 _tokenId) public whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0) && msg.sender != address(0));
        require(_to != msg.sender);

        // You can only send your own gem.
        require(_ownsGEM(msg.sender, _tokenId));

        // storage variables update
        _transferGEM(msg.sender, _to, _tokenId);

        // Reassign ownership,
        safeTransferFrom(msg.sender, _to, _tokenId);

        emit TransferGEM(msg.sender, _to, _tokenId);
    }

    function transferGEMFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        require(_to != _from);
        require(_approvedFor(msg.sender, _tokenId));
        require(_ownsGEM(_from, _tokenId));

        _transferGEM(_from, _to, _tokenId);
        safeTransferFrom(_from, _to, _tokenId);
        //emit transfer event
        emit TransferGEM(_from, _to, _tokenId);
    }

    function approveGEM(address _to, uint256 _tokenId) public whenNotPaused {
        // Only an owner can grant transfer approval.
        require(_ownsGEM(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /**
     * @notice Creates a premined pool of GEMs based oon their attribute passed in the parameters and assigns their ownership to the contract.
     * @param _rarities The rarities of the GEMs to be created.
     * @param _colors The colors of the GEMs to be created.
     * @param _values The values of the GEMs to be created.
     * @param _quadrants The quadrants of the GEMs to be created.
     * @return The IDs of the newly created GEMs.
     */
    function createPreminedGEMPool(
        Rarity[] memory _rarities,
        string[] memory _colors,
        uint256[] memory _values,
        bytes4[] memory _quadrants,
        string[] memory _colorStyle,
        string[]memory _backgroundColor,
        string[] memory _backgroundColorStyle,
        uint256[] memory _cooldownPeriod
    ) external onlyTreasuryOrAdmin whenNotPaused returns (uint256[] memory) {
        require(
            _rarities.length == _colors.length &&
            _colors.length == _values.length &&
            _values.length == _quadrants.length,
            "Input arrays must have the same length"
        );

        uint256[] memory newGemIds = new uint256[](_rarities.length);

        for (uint256 i = 0; i < _rarities.length; i++) {
            Gem memory _Gem = Gem({
                tokenId: 0,
                rarity: _rarities[i],
                quadrants: _quadrants[i],
                color: _colors[i],
                value: _values[i],
                colorStyle: _colorStyle[i],
                backgroundColor: _backgroundColor[i],
                backgroundColorStyle: _backgroundColorStyle[i],
                cooldownPeriod: _cooldownPeriod[i],
                isForSale: false,
                isMinable: false
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

            emit Created(newGemId, _rarities[i], _quadrants[i], _colors[i], _values[i], msg.sender);
            newGemIds[i] = newGemId;
        }

        return newGemIds;
    }


    function setMiningCooldown(uint256 _miningCooldown) external onlyOwner {
        require(_miningCooldown != 0, "mining cooldown must be greater than 0");
        miningCooldown = _miningCooldown;
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

    function _approve(uint256 _tokenId, address _approved) internal {
        GEMIndexToApproved[_tokenId] = _approved;
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------VIEW FUNCTIONS--------------------------------------------
    //---------------------------------------------------------------------------------------

    function preMintedGemsAvailable() external view returns (uint256[] memory GemsAvailable) {
        return tokensOfOwner(address(this));
    }

    function _ownsGEM(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return GEMIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return GEMIndexToApproved[_tokenId] == _claimant;
    }


    function balanceOf(address _owner) public view override returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function ownerOfGEM(uint256 _tokenId) external view returns (address owner) {
        owner = GEMIndexToOwner[_tokenId];

        require(owner != address(0));
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
