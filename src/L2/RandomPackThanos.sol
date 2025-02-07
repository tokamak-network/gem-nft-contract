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
contract RandomPackThanos is ProxyStorage, ReentrancyGuard, IERC721Receiver, AuthControl, DRBConsumerBase, RandomPackStorage {
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
    function unpause() public onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @notice we implement the receive function in order to receive TON (as a native token) 
     */
    receive() external payable {
        // we send the funds to the treasury
        (bool s,) = treasury.call{value: msg.value}("");
        if(!s) {
            revert FailedToSendFeesToTreasury();
        }
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------INITIALIZE FUNCTIONS-----------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Initializes the RandomPack contract with the given parameters.
     * @param _coordinator Address of the  DRBCoordinator contract.
     * @param _gemFactory Address of the gem factory contract.
     * @param _treasury Address of the treasury contract.
     * @param _randomPackFees Fees for requesting a random pack
     */
    function initialize(
        address _coordinator,  
        address _gemFactory, 
        address _treasury, 
        uint256 _randomPackFees
    ) external {
        if(initialized) {
            revert AlreadyInitialized();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __DRBConsumerBase_init(_coordinator);
        gemFactory = _gemFactory;
        treasury = _treasury;
        randomPackFees = _randomPackFees;
        callbackGasLimit = 2100000;
        perfectCommonGemURI = "";
        initialized = true;
    }

    /** 
     * @notice Sets the address of the gem factory.
     * @param _gemFactory New address of the gem factory contract.
     */
    function setGemFactory(address _gemFactory) external onlyOwner {
        if(_gemFactory == address(0)) {
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
        if(_randomPackFees == 0) {
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

    /**
     * @notice Sets the probability for the fulfillRandomness function based on the rarity
     * @param _commonProb probability of getting a common gem => must be set in percentage
     * @param _rareProb probability of getting a rare gem => must be set in percentage
     * @param _uniqueProb probability of getting a unique gem => must be set in percentage
     * @param _epicProb probability of getting a epic gem => must be set in percentage
     * @param _legendaryProb probability of getting a legendary gem => must be set in percentage
     * @param _mythicProb probability of getting a mythic gem => must be set in percentage
     * @dev only callable by the owner
     * @dev at least 1 probability must be greater than 0
     * @dev the sum of the probability must be equal to 100
     */
    function setProbabilities(
        uint8 _commonProb,
        uint8 _rareProb,
        uint8 _uniqueProb,
        uint8 _epicProb,
        uint8 _legendaryProb,
        uint8 _mythicProb
    ) external onlyOwner {
        // ensure at least one probability is > 0 and that the sum = 100
        if(
            _commonProb == 0 && 
            _rareProb == 0 && 
            _uniqueProb == 0 && 
            _epicProb == 0 && 
            _legendaryProb == 0 && 
            _mythicProb == 0
        ) {
            revert invalidProbabilities();
        }
        uint8 sumOfProb = _commonProb + _rareProb + _uniqueProb + _epicProb + _legendaryProb + _mythicProb;
        if(sumOfProb != DIVIDER) {
            revert invalidProbabilities();
        }

        probabilities[0] = _commonProb;
        probabilities[1] = _rareProb;
        probabilities[2] = _uniqueProb;
        probabilities[3] = _epicProb;
        probabilities[4] = _legendaryProb;
        probabilities[5] = _mythicProb;

        // used for sanity check in requestRandomGem function
        probInitialized = true;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------EXTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Requests a random GEM and pays the required fees.
     * @return uint256 Returns the request ID for the randomness request.
     * @dev function has nonReentrant modifier and follows CEI
     * @dev the function reverts if probabilities were not initialized
     */
    function requestRandomGem() external payable whenNotPaused nonReentrant returns(uint256) {
        // revert if every probabilities are equal to 0
        if(!probInitialized) {
            revert invalidProbabilities();
        }
        // msg.sender must be different from address(0)
        if(msg.sender == address(0)) {
            revert InvalidAddress();
        }
        //users pays upfront fees
        (bool s,) = address(this).call{value: randomPackFees}("");
        if(!s) {
            revert FailedToPayFees();
        }
        
        // Request randomness from the consumer with default parameters
        (uint256 directFundingCost, uint256 requestId) = requestRandomness(0,0,callbackGasLimit);        

        // Update the request mapping with details of the request
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        unchecked {
            // Increment the request count
            requestCount++;
        }

        if(msg.value > directFundingCost + randomPackFees) { // if there is ETH to refund
            // Refund excess ETH to the user if they overpaid
            uint256 ethToRefund = msg.value - directFundingCost - randomPackFees;
            (bool success, ) = msg.sender.call{value: ethToRefund}("");
            if(!success) {
                revert FailedToSendEthBack();
            }
            // Emit an event for the ETH refund
            emit EthSentBack(ethToRefund);
        }

        // Emit an event for the random GEM request
        emit RandomGemRequested(msg.sender, requestId);
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
     * @param requestId The ID of the randomness request.
     * @param randomNumber The random number generated.
     * @dev the function lists down the Gems available in the treasury (not locked) through the availableGemsFandomPack function 
     * @dev selects the Gem based on the rarity probabilities set
     * @dev if there is no gem available, the function creates a new common gem with specific attributes
     */
    function fulfillRandomWords(uint256 requestId, uint256 randomNumber) internal override {
        // staking the storage for gaz savings
        GemPackRequestStatus storage request = s_requests[requestId];
        
        // the request must be requested
        if(!request.requested) {
            revert RequestNotMade();
        }
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = randomNumber;

        // mints a new common gem if there is no Gems available 
        if (!IGemFactory(gemFactory).availableGemsRandomPack()) {
            mintCommonGem(request);
            return;
        }

        // getting a random value between 1 and 100
        uint256 selectedProb = randomNumber % DIVIDER;

        // we check for each rarity if the random value generated is corresponding. e.g if 5% of getting mythic => selectedProb must be >= 95
        for (uint8 rarity = 5; rarity > 0; --rarity) {
            if (selectedProb >= sumProbabilities(rarity)) {
                if (transferGemByRarity(request, rarity, randomNumber)) {
                    return;
                }
            } 
        }

        // transferring an existing common gem if there is Gem(s) available but none of them were chosen
        if (transferGemByRarity(request, 0, randomNumber)) {
            return;
        }
            
        // mints a new common gem if there is Gem available but none of them were chosen
        mintCommonGem(request);
    }

    /**
     * @notice Mints a new common gem and transfers it to the requester.
     * @param request The request object containing requester details.
     * @dev this function reverts if there is no WSTON availbe as a collateral for a new Common Gem
     */
    function mintCommonGem(GemPackRequestStatus storage request) private {
        request.chosenTokenId = ITreasury(treasury).createPreminedGEM(GemFactoryStorage.Rarity.COMMON, [0, 0], [1, 1, 1, 1], "");
        ITreasury(treasury).transferTreasuryGEMto(request.requester, request.chosenTokenId);
        emit CommonGemMinted();
    }

    /**
     * @notice Transfers a gem of a specific rarity to the requester if available.
     * @param request The request object containing requester details.
     * @param rarity The rarity level of the gem to transfer.
     * @param randomNumber The random number used to select the rarity.
     * @dev the random number is also used to choose the token Id from the array of available Gems for a specific rarity
     * @return True if a gem was successfully transferred, false otherwise
     */
    function transferGemByRarity(GemPackRequestStatus storage request, uint8 rarity, uint256 randomNumber) private returns (bool) {
        if(probabilities[rarity] > 0) {
            (uint256 gemCount, uint256[] memory tokenIds) = IGemFactory(gemFactory).getGemListAvailableByRarity(rarity);
            if (gemCount > 0) {
                uint256 modNbGemsAvailable = randomNumber % gemCount;
                request.chosenTokenId = tokenIds[modNbGemsAvailable];
                ITreasury(treasury).transferTreasuryGEMto(request.requester, request.chosenTokenId);
                emit RandomGemTransferred(request.chosenTokenId, request.requester);
                return true;
            }
        }
        return false;
    }
    /**
     * @notice Sums the probabilities up to a given index.
     * @param end The index up to which to sum the probabilities.
     * @return The sum of probabilities up to the given index.
     */
    function sumProbabilities(uint256 end) private view returns (uint256) {
        uint8 sum = 0;
        for (uint8 i = 0; i <= end-1; i++) {
            sum += probabilities[i];
        }
        return sum;
    }




    //---------------------------------------------------------------------------------------
    //-------------------------------STORAGE GETTERS-----------------------------------------
    //---------------------------------------------------------------------------------------

    function getTreasuryAddress() external view returns(address) {return treasury;}
    function getGemFactoryAddress() external view returns(address) {return gemFactory;}
    function getCallbackGasLimit() external view returns(uint32) {return callbackGasLimit;}
    function getRequestCount() external view returns(uint256) {return requestCount;}
    function getRandomPackFees() external view returns(uint256) {return randomPackFees;}
    function getPerfectCommonGemURI() external view returns(string memory) {return perfectCommonGemURI;}
    function getPaused() external view returns(bool) {return paused;}
}