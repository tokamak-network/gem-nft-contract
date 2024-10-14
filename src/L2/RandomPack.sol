// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGemFactory } from "../interfaces/IGemFactory.sol";
import { GemFactoryStorage } from "./GemFactoryStorage.sol";  
import {AuthControl} from "../common/AuthControl.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { RandomPackStorage } from "./RandomPackStorage.sol";
import "../proxy/ProxyStorage.sol";

import {DRBConsumerBase} from "./Randomness/DRBConsumerBase.sol";
import {IDRBCoordinator} from "../interfaces/IDRBCoordinator.sol";

interface ITreasury {
    function transferWSTON(address _to, uint256 _amount) external returns(bool);
    function transferTreasuryGEMto(address _to, uint256 _tokenId) external returns(bool);
    function getWSTONBalance() external view returns (uint256);
    function createPreminedGEM( 
        GemFactoryStorage.Rarity _rarity,
        uint8[2] memory _color, 
        uint8[4] memory _quadrants,  
        string memory _tokenURI
    ) external returns (uint256);
}

/**
 * @title RandomPack Contract for GEM Distribution
 * @author TOKAMAK OPAL TEAM
 * @notice This contract facilitates the creation and distribution of random GEM tokens.
 * @dev The contract integrates with external systems (Gem Factory, Treasury, and a Randomness Coordinator).
 * It allows users to request random GEMs by paying a fee and handles the minting and transfer of GEMs.
 * The contract includes mechanisms for pausing operations and managing fees.
 */
contract RandomPack is ProxyStorage, ReentrancyGuard, IERC721Receiver, AuthControl, DRBConsumerBase, RandomPackStorage {
    using SafeERC20 for IERC20;

    /**
     * @notice Modifier to ensure the contract is not paused.
     */
    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    /**
     * @notice Modifier to ensure the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @notice Pauses the contract, preventing certain actions.
     * @dev Only callable by the owner when the contract is not paused.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @notice Unpauses the contract, allowing actions to be performed.
     * @dev Only callable by the owner when the contract is paused.
     */
    function unpause() public onlyOwner whenNotPaused {
        paused = false;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------INITIALIZE FUNCTIONS-----------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the RandomPack contract with the given parameters.
     * @param _coordinator Address of the  DRBCoordinator contract.
     * @param _ton Address of the TON token.
     * @param _gemFactory Address of the gem factory contract.
     * @param _treasury Address of the treasury contract.
     * @param _randomPackFees Fees for requesting a random pack.
     */
    function initialize(
        address _coordinator,  
        address _ton, 
        address _gemFactory, 
        address _treasury, 
        uint256 _randomPackFees
    ) external {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __DRBConsumerBase_init(_coordinator);
        gemFactory = _gemFactory;
        treasury = _treasury;
        ton = _ton;
        randomPackFees = _randomPackFees;
        callbackGasLimit = 600000;
        perfectCommonGemURI = "";
    }

    /** 
     * @notice Sets the address of the gem factory.
     * @param _gemFactory New address of the gem factory contract.
     */
    function setGemFactory(address _gemFactory) external onlyOwner {
        if(gemFactory == address(0)) {
            revert InvalidAddress();
        }
        gemFactory = _gemFactory;
        emit GemFactoryAddressUpdated(_gemFactory);
    }

    /**
     * @notice Sets the fees for requesting a random pack.
     * @param _randomPackFees New fees for random pack requests.
     */
    function setRandomPackFees(uint256 _randomPackFees) external onlyOwner {
        if(randomPackFees == 0) {
            revert RandomPackFeesEqualToZero();
        }
        randomPackFees = _randomPackFees;
        emit RandomPackFeesUpdated(_randomPackFees);
    }

    /**
     * @notice Sets the address of the treasury.
     * @param _treasury New address of the treasury contract.
     */
    function setTreasury(address _treasury) external onlyOwner {
        if(_treasury == address(0)) {
            revert InvalidAddress();
        }
        treasury = _treasury;
        emit TreasuryAddressUpdated(_treasury);
    }

    /**
     * @notice Sets the URI for the perfect common GEM.
     * @param _tokenURI New URI for the perfect common GEM.
     */
    function setPerfectCommonGemURI(string memory _tokenURI) external onlyOwner {
        perfectCommonGemURI = _tokenURI;
        emit PerfectCommonGemURIUpdated(_tokenURI);
    }

    /**
     * @notice Sets the gas limit for the callback function.
     * @param _callbackGasLimit New gas limit for the callback function.
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
        emit CallBackGasLimitUpdated(_callbackGasLimit);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------EXTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Requests a random GEM and pays the required fees.
     * @return uint256 Returns the request ID for the randomness request.
     * @dev function has nonReentrant modifier and follows CEI
     */
    function requestRandomGem() external payable whenNotPaused nonReentrant returns(uint256) {
        if(msg.sender == address(0)) {
            revert InvalidAddress();
        }
        //users pays upfront fees
        //user must approve the contract for the fees amount before calling the function
        IERC20(ton).safeTransferFrom(msg.sender, address(this), randomPackFees);
        
        // Request randomness from the consumer with default parameters
        (uint256 directFundingCost, uint256 requestId) = requestRandomness(0,0,callbackGasLimit);        

        // Update the request mapping with details of the request
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            // Increment the request count
            requestCount++;
        }

        // Refund excess ETH to the user if they overpaid
        if(msg.value > directFundingCost) { // if there is ETH to refund
            (bool success, ) = msg.sender.call{value:  msg.value - directFundingCost}("");
            if(!success) {
                revert FailedToSendEthBack();
            }
            // Emit an event for the ETH refund
            emit EthSentBack(msg.value - directFundingCost);
        }

        // Emit an event for the random GEM request
        emit RandomGemRequested(msg.sender);
        return requestId;
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
     * @notice Fulfills the randomness request with the given random number and transfers a random GEM to the appropriate user
     * @dev the function lists down the Gems available in the treasury (not locked) through the getGemListAvailableForRandomPack function 
     * @dev if there is no gem available, the function creates a new common gem with specific attributes
     * @param requestId The ID of the randomness request.
     * @param randomNumber The random number generated.
     */
    function fulfillRandomWords(uint256 requestId, uint256 randomNumber) internal override {
        if(!s_requests[requestId].requested) {
            revert RequestNotMade();
        }
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = randomNumber;

        (uint256 gemCount, uint256[] memory tokenIds) = IGemFactory(gemFactory).getGemListAvailableForRandomPack();

        if(gemCount > 0) {
            // same calculation as for the mining process
            uint256 modNbGemsAvailable = (randomNumber % gemCount);
            s_requests[requestId].chosenTokenId = tokenIds[modNbGemsAvailable];
            // transfer the gem from the treasury to the user.
            ITreasury(treasury).transferTreasuryGEMto(s_requests[requestId].requester, s_requests[requestId].chosenTokenId);
            emit RandomGemTransferred(s_requests[requestId].chosenTokenId, s_requests[requestId].requester);
        } else {
            // if there is no gem available in the pool, we mint a new perfect common gem. note that it reverts if the treasury does not have enough WSTON.
            s_requests[requestId].chosenTokenId = ITreasury(treasury).createPreminedGEM(GemFactoryStorage.Rarity.COMMON, [0,0], [1,1,1,1], "");
            ITreasury(treasury).transferTreasuryGEMto(msg.sender, s_requests[requestId].chosenTokenId);
            emit CommonGemMinted();
        }
    }


    //---------------------------------------------------------------------------------------
    //-------------------------------STORAGE GETTERS-----------------------------------------
    //---------------------------------------------------------------------------------------

    function getTreasuryAddress() external view returns(address) {return treasury;}
    function getGemFactoryAddress() external view returns(address) {return gemFactory;}
    function getTonAddress() external view returns(address) {return ton;}
    function getCallbackGasLimit() external view returns(uint32) {return callbackGasLimit;}
    function getRequestCount() external view returns(uint256) {return requestCount;}
    function getRandomPackFees() external view returns(uint256) {return randomPackFees;}
    function getPerfectCommonGemURI() external view returns(string memory) {return perfectCommonGemURI;}
}