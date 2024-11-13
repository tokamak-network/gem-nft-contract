// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ProxyStorage} from "../proxy/ProxyStorage.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISeigManager} from "../interfaces/ISeigManager.sol";
import {IDepositManager} from "../interfaces/IDepositManager.sol";
import {L1WrappedStakedTONStorage} from "./L1WrappedStakedTONStorage.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICandidate {
    function updateSeigniorage() external returns (bool);
}

interface ITON {
    function approveAndCall(address spender, uint256 amount, bytes memory data) external returns (bool);
    function swapFromTON(uint256 tonAmount) external returns (bool);
}

/**
 * @title L1WrappedStakedTON
 * @author TOKAMAK OPAL TEAM
 * @dev This contract allows users to deposit WTON or TON and receive WSTON in return.
 * It manages staking, withdrawal requests, and updates seigniorage.
 * The contract is upgradeable and uses OpenZeppelin libraries for security and functionality.
 */
contract L1WrappedStakedTON is
    ProxyStorage,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuard,
    L1WrappedStakedTONStorage
{
    using SafeERC20 for IERC20;
        
    /**
     * @notice Modifier to ensure the contract is not paused.
     */
    modifier whenNotPaused() {
        if (paused) {
            revert ContractPaused();
        }
        _;
    }

    /**
     * @notice Modifier to ensure the contract is paused.
     */
    modifier whenPaused() {
        if (!paused) {
            revert ContractNotPaused();
        }
        _;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * @return The number of decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 27;
    }

    /**
     * @dev Pauses the contract, preventing certain functions from being called.
     * Can only be called by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing certain functions to be called.
     * Can only be called by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INITIALIZATION FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @dev initializing the contract.
     * @param _layer2Address The address of the Layer 2 contract.
     * @param _wton The address of the WTON token contract.
     * @param _ton The address of the TON token contract.
     * @param _depositManager The address of the DepositManager contract.
     * @param _seigManager The address of the SeigManager contract.
     * @param _name The name of the ERC20 token.
     * @param _symbol The symbol of the ERC20 token.
     */
    function initialize(
        address _layer2Address,
        address _wton,
        address _ton,
        address _depositManager,
        address _seigManager,
        address _owner,
        uint256 _minimumWithdrawalAmount,
        uint8 _maxNumWithdrawal,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init(_owner);
        depositManager = _depositManager;
        seigManager = _seigManager;
        layer2Address = _layer2Address;
        wton = _wton;
        ton = _ton;
        minimumWithdrawalAmount = _minimumWithdrawalAmount;
        maxNumWithdrawal = _maxNumWithdrawal;
        stakingIndex = DECIMALS;
    }

    /**
     * @notice function to update the depositManager contract address
     */
    function setDepositManagerAddress(address _depositManager) external onlyOwner {
        depositManager = _depositManager;
    }

    /**
     * @notice function to update the seigManager contract address
     */
    function setSeigManagerAddress(address _seigManager) external onlyOwner {
        seigManager = _seigManager;
    }

    /**
     * @notice function to update the maxNumWithdrawal variable
     */
    function setMaxNumWithdrawal(uint8 _maxNumWithdrawal) external onlyOwner {
        maxNumWithdrawal = _maxNumWithdrawal;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------EXTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @dev Handles the deposits callback for TON or WTON tokens.
     * @param _to The address to which the tokens are approved.
     * @param _amount The amount of tokens approved.
     * @param data Additional data for the approval.
     * @return Returns true if the operation is successful.
     */
    function onApprove(address _to, address /*spender*/, uint256 _amount, bytes calldata data) external returns (bool) {
        if (msg.sender != ton && msg.sender != wton) {
            revert InvalidCaller();
        }

        (address to, uint256 amount) = _decodeDepositAndGetWSTONOnApproveData(data);
        emit decodeSuccess(to, amount);

        if (_to != to || _amount != amount) {
            revert InvalidToOrAmount();
        }

        bool depositSuccess;
        if (msg.sender == ton) {
            depositSuccess = _depositAndGetWSTONTo(to, amount, true);
        } else {
            depositSuccess = _depositAndGetWSTONTo(to, amount, false);
        }

        if (!depositSuccess) {
            revert DepositFailed();
        }

        return true;
    }
    /**
     * @dev Decodes the data for deposit and WSTON approval.
     * @param data The calldata containing the encoded data.
     * @return to The address to which the tokens are approved.
     * @return amount The amount of tokens approved.
     */

    function _decodeDepositAndGetWSTONOnApproveData(bytes calldata data)
        internal
        pure
        returns (address to, uint256 amount)
    {
        if (data.length != 64) {
            revert InvalidOnApproveData();
        }
        assembly {
            // The layout of a "bytes calldata" is:
            // The first 32 bytes: to
            // The next 32 bytes: amount

            // Load the address from the first 32 bytes of data
            to := shr(96, calldataload(add(data.offset, 12))) // Shift right to get the address

            // Load the amount from the next 32 bytes of data
            amount := calldataload(add(data.offset, 32))
        }
    }

    /**
     * @dev Deposits WTON and mints WSTON for the sender.
     * @param _amount The amount of WTON to deposit.
     */
    function depositWTONAndGetWSTON(uint256 _amount, bool _token) external whenNotPaused nonReentrant {
        if (!_depositAndGetWSTONTo(msg.sender, _amount, _token)) {
            revert DepositFailed();
        }
    }

    /**
     * @dev Deposits WTON and mints WSTON for a specified address.
     * @param _to The address that will receive the minted WSTON.
     * @param _amount The amount of WTON to deposit.
     */
    function depositWTONAndGetWSTONTo(address _to, uint256 _amount, bool _token) external whenNotPaused nonReentrant {
        if (!_depositAndGetWSTONTo(_to, _amount, _token)) {
            revert DepositFailed();
        }
    }

    /**
     * @notice Requests a withdrawal of WSTON.
     * @dev This function allows users to request a withdrawal of their WSTON tokens.
     * The withdrawal will be processed after a delay specified by the DepositManager.
     * @param _wstonAmount The amount of WSTON to withdraw.
     * @custom:requirements The caller must have a balance of at least `_wstonAmount` WSTON.
     * The contract must not be paused.
     * @custom:events Emits a `WithdrawalRequested` event upon successful request.
     * @custom:reverts Reverts if the caller does not have enough WSTON balance.
     */
    function requestWithdrawal(uint256 _wstonAmount) external whenNotPaused {
        uint256 delay = IDepositManager(depositManager).getDelayBlocks(layer2Address);
        if (!_requestWithdrawal(_wstonAmount, delay)) {
            revert WithdrawalRequestFailed();
        }
    }

    /**
     * @notice Claims all eligible withdrawal requests for the caller. User gets TON only
     * @dev This function processes all withdrawal requests that are eligible for claiming.
     * It transfers the corresponding TON or WTON to the caller.
     */
    function claimWithdrawalTotal() external whenNotPaused {
        if (!_claimWithdrawalTotal()) {
            revert ClaimWithdrawalFailed();
        }
    }
    /**
     * @notice Claims a specific withdrawal request for the caller by index. User gets TON only
     * @dev This function processes a withdrawal request at a given index if it is eligible for claiming.
     * It transfers the corresponding TON or WTON to the caller.
     * @param _index The index of the withdrawal request to claim.
     */

    function claimWithdrawalIndex(uint256 _index) external whenNotPaused {
        if (!_claimWithdrawalIndex(_index)) {
            revert ClaimWithdrawalFailed();
        }
    }

    /**
     * @notice Updates the seigniorage for the Layer 2 staking contract.
     * @dev This function interacts with the SeigManager to update the seigniorage for the specified Layer 2 address.
     * It is used to ensure that the staking rewards are up-to-date.
     * @return bool Returns true if the seigniorage update is successful.
     */
    function updateSeigniorage() public returns (bool) {
        return ISeigManager(seigManager).updateSeigniorageLayer(layer2Address);
    }

    //---------------------------------------------------------------------------------------
    //--------------------------INTERNAL FUNCTIONS-------------------------------------------
    //---------------------------------------------------------------------------------------

    /*
     * @dev Internal function to deposit WTON and mint WSTON for a specified address.
     * Transfers `_amount` of WTON to this contract, updates seigniorage, 
     * stakes the amount in the DepositManager, and mints WSTON.
     * @param _to The address that will receive the minted WSTON.
     * @param _amount The amount of WTON to be deposited and staked.
     * @param _token true = TON / false = WTON
     * @return bool Returns true if the operation is successful.
     * Requirements:
     * - `_amount` must not be zero.
     * - `_to` must have allowed the contract to spend at least `_amount` of WTON.
     * - WTON transfer to this contract must succeed.
     * - Seigniorage update must succeed if necessary.
     * - Approval for depositManager to spend on behalf of this contract must succeed.
     * - Staking the amount in DepositManager must succeed.
     */

    function _depositAndGetWSTONTo(address _to, uint256 _amount, bool _token) internal returns (bool) {
        // adding the user to the list => keeping track of withdrawals that are claimable
        addUser(_to);

        // check for wrong amounts
        if (_amount == 0) {
            revert WrontAmount();
        }

        // we update seigniorage to get the latest sWTON balance
        if (lastSeigBlock != 0 && ISeigManager(seigManager).lastSeigBlock() < block.number) {
            if (!ICandidate(layer2Address).updateSeigniorage()) {
                revert SeigniorageUpdateFailed();
            }
            emit SeigniorageUpdated();
        }
        lastSeigBlock = block.number;

        // updating the staking index
        stakingIndex = updateStakingIndex();
        emit StakingIndexUpdated(stakingIndex);

        uint256 wstonAmount;

        if (!_token) {
            // user transfers wton to this contract
            IERC20(wton).safeTransferFrom(_to, address(this), _amount);

            // approve depositManager to spend on behalf of the WrappedStakedTON contract
            if (IERC20(wton).allowance(address(this), depositManager) < _amount) {
                IERC20(wton).approve(depositManager, type(uint256).max);
            }

            // deposit _amount to DepositManager
            if (!IDepositManager(depositManager).deposit(layer2Address, _amount)) {
                revert DepositFailed();
            }

            wstonAmount = getDepositWstonAmount(_amount);
        } else {
            // user transfers ton to this contract
            IERC20(ton).safeTransferFrom(_to, address(this), _amount);

            // Encode the layer2 address into bytes
            bytes memory data = abi.encode(depositManager, layer2Address);
            if (!ITON(ton).approveAndCall(wton, _amount, data)) {
                revert ApproveAndCallFailed();
            }
            wstonAmount = getDepositWstonAmount(_amount * 1e9);
        }

        // we mint WSTON
        _mint(_to, wstonAmount);

        emit Deposited(_to, _token, _amount, wstonAmount, block.timestamp, block.number);

        return true;
    }

    /**
     * @dev Internal function to handle withdrawal requests.
     * @param _wstonAmount The amount of WSTON to withdraw.
     * @param delay The delay in blocks before the withdrawal can be processed.
     * @return bool Returns true if the operation is successful.
     */
    function _requestWithdrawal(uint256 _wstonAmount, uint256 delay) internal returns (bool) {
        if (balanceOf(msg.sender) < _wstonAmount) {
            revert NotEnoughFunds();
        }

        // minimum withdrawal amount implemented to avoid the function claimWithdrawal to run out of gas
        if(_wstonAmount < minimumWithdrawalAmount) {
            revert MinimalWithdrawalAmount();
        }

        // revert if the user has reached the maximum number of withdrawal requests
        if(numWithdrawalRequestsByUser[msg.sender] == maxNumWithdrawal) {
            revert MaximumNumberOfWithdrawalsReached();
        }

        // updating the staking index
        stakingIndex = updateStakingIndex();
        emit StakingIndexUpdated(stakingIndex);

        // calculate the WTON amount to withdraw
        uint256 _amountToWithdraw = (_wstonAmount * stakingIndex) / DECIMALS;

        if (!IDepositManager(depositManager).requestWithdrawal(layer2Address, _amountToWithdraw)) {
            revert WithdrawalRequestFailed();
        }

        // pushing a new withdrawal request to the withdrawalRequests[] array
        withdrawalRequests[msg.sender].push(
            WithdrawalRequest({
                withdrawableBlockNumber: block.number + delay,
                amount: _amountToWithdraw,
                processed: false
            })
        );

        unchecked {
            withdrawalRequestIndex[msg.sender] += 1;
            numWithdrawalRequestsByUser[msg.sender] += 1;
        }

        // Burn wstonAmount
        _burn(msg.sender, _wstonAmount);

        emit WithdrawalRequested(msg.sender, _wstonAmount);
        return true;
    }

    /**
     * @dev Internal function to handle the claim of all withdrawal requests related to msg.sender. Funds are sent in TON only
     * @return bool Returns true if the operation is successful.
     */
    function _claimWithdrawalTotal() internal returns (bool) {
        uint256 totalClaimableAmount = 0;
        uint256 currentBlock = block.number;

        // Iterate over each withdrawal request for the user
        for (uint256 j = 0; j < withdrawalRequests[msg.sender].length; ++j) {
            WithdrawalRequest memory request = withdrawalRequests[msg.sender][j];

            // Check if the request is eligible for claiming
            if (!request.processed && request.withdrawableBlockNumber <= currentBlock) {
                withdrawalRequests[msg.sender][j].processed = true;
                totalClaimableAmount += request.amount;
            }
        }

        // Revert if no request is eligible
        if (totalClaimableAmount == 0) {
            revert NoClaimableAmount(msg.sender);
        }

        // reset the number of withdrawal requests for this user
        delete numWithdrawalRequestsByUser[msg.sender];

        totalClaimableAmount = totalClaimableAmount / 10 ** 9;
        /// if there is enough funds in the contract, it means that someone else has already processRequest
        /// this avoid the scenario where processRequest fails because it was already called previously 
        /// and no request can be processed anymore in the depositManager
        if(IERC20(ton).balanceOf(address(this)) >= totalClaimableAmount) {
            IERC20(ton).safeTransfer(msg.sender, totalClaimableAmount);
        } else{
            uint256 _numWithdrawableRequests = numWithdrawableRequests();
            if(_numWithdrawableRequests > 0) {               
                if (!IDepositManager(depositManager).processRequests(layer2Address, _numWithdrawableRequests, true)) {
                    revert ProcessRequestFailed();
                }
            }
            IERC20(ton).safeTransfer(msg.sender, totalClaimableAmount);
        }

        emit WithdrawalProcessed(msg.sender, totalClaimableAmount);
        return true;
    }

    /**
     * @dev Internal function to handle the claim of a withdrawal requests related to a specific index. Funds are sent in TON only
     * @param _index the index the user wishes to claim
     * @return bool Returns true if the operation is successful.
     */
    function _claimWithdrawalIndex(uint256 _index) internal whenNotPaused returns (bool) {
        if (_index >= withdrawalRequests[msg.sender].length) {
            revert NoRequestToProcess();
        }

        // stack the withdrawal request corresponding to the index 
        WithdrawalRequest storage request = withdrawalRequests[msg.sender][_index];

        // revert if the request has been procesed
        if (request.processed == true) {
            revert RequestAlreadyProcessed();
        }

        // revert if the delay has not elapsed
        if (request.withdrawableBlockNumber > block.number) {
            revert WithdrawalDelayNotElapsed();
        }

        // set the processed storage to true
        withdrawalRequests[msg.sender][_index].processed = true;

        // decrease the number of withdrawal requests for this user
        numWithdrawalRequestsByUser[msg.sender] --;

        // staking the amount to be withdrawn
        uint256 amount = (request.amount) / 10 ** 9;

        /// if there is enough funds in the contract, it means that someone else has already processRequest
        /// this avoid the scenario where processRequest fails because it was already called previously 
        /// and no request can be processed anymore in the depositManager
        if(IERC20(ton).balanceOf(address(this)) >= amount) {
            IERC20(ton).safeTransfer(msg.sender, amount);
        } 
        else {
            uint256 _numWithdrawableRequests = numWithdrawableRequests();
            if(_numWithdrawableRequests > 0) {               
                if (!IDepositManager(depositManager).processRequests(layer2Address, _numWithdrawableRequests, true)) {
                    revert ProcessRequestFailed();
                }
            }
            IERC20(ton).safeTransfer(msg.sender, amount);
        }

        emit WithdrawalProcessed(msg.sender, amount);
        return true;
    }

    /**
     * @notice process one or multiple requests. This function can be called by anyone
     */
    function processWithdrawalRequest(uint256 numRequests) external returns(bool) {
        if (!IDepositManager(depositManager).processRequests(layer2Address, numRequests, true)) {
                revert ProcessRequestFailed();
        }
        return true;
    }

    /**
     * @notice Updates the staking index based on the current total stake and total supply.
     * @dev This function recalculates the staking index to reflect the current staking status.
     * It ensures that the staking index is updated only if there is a positive total supply and total stake.
     * @return uint256 Returns the updated staking index.
     * @custom:events Emits a `StakingIndexUpdated` event with the new staking index.
     */
    function updateStakingIndex() internal returns (uint256) {
        uint256 _stakingIndex;
        uint256 totalStake = stakeOf();

        if (totalSupply() > 0 && totalStake > 0) {
            // Multiply first to avoid precision loss, then divide
            _stakingIndex = (totalStake * DECIMALS) / totalSupply();
        } else {
            _stakingIndex = stakingIndex;
        }

        stakingIndex = _stakingIndex;
        return _stakingIndex;
    }

    /**
     * @notice Adds a user to the list of users if they are not already present.
     * @dev This function checks if the user exists in the list and adds them if not.
     * It is used to keep track of users who have interacted with the contract.
     * @param user The address of the user to add.
     */
    function addUser(address user) internal {
        if (!userExists[user]) {
            users.push(user);
            userExists[user] = true;
        }
    }

    /**
     * @notice Calculates the amount of WSTON to be minted based on the deposit amount.
     * @dev This function uses the current staking index to determine the equivalent WSTON amount for a given deposit.
     * @param _amount The amount of WTON being deposited.
     * @return uint256 Returns the calculated WSTON amount.
     */
    function getDepositWstonAmount(uint256 _amount) internal view returns (uint256) {
        uint256 _wstonAmount = (_amount * DECIMALS) / stakingIndex;
        return _wstonAmount;
    }
    
    /**
     * @notice calculating the number of withdrawal requests that can be processed 
     * @dev we fetch the number of requests made by the contract, as well as the number of the last index
     * @dev we iterrate over the number of pending requests and check if it is withdrawable 
     * @return count the total number of withdrawable requests
     */
    function numWithdrawableRequests() internal view returns (uint256) {
        uint256 numRequests = IDepositManager(depositManager).numRequests(layer2Address, address(this));
        uint256 index = IDepositManager(depositManager).withdrawalRequestIndex(layer2Address, address(this));
        uint256 count;

        if (numRequests == 0) return 0;
        uint256 numberPendingRequests = numRequests - index;

        for(uint256 i = 0; i < numberPendingRequests; ++i) {
            (uint128 withdrawableBlockNumber,,bool processed) = IDepositManager(depositManager).withdrawalRequest(layer2Address, address(this), index  + i);
            if(withdrawableBlockNumber <= block.number && !processed) {
                count++;
            }
        }
        return count;
    }

    //---------------------------------------------------------------------------------------
    //------------------------VIEW FUNCTIONS / STORAGE GETTERS-------------------------------
    //---------------------------------------------------------------------------------------

    function stakeOf() public view returns (uint256) {
        return ISeigManager(seigManager).stakeOf(layer2Address, address(this));
    }

    function getLastWithdrawalRequest(address requester) external view returns (WithdrawalRequest memory) {
        uint256 index = withdrawalRequestIndex[requester] - 1;
        WithdrawalRequest memory request = withdrawalRequests[requester][index];
        return request;
    }

    /**
     * @notice Calculates the total claimable amount for a specific user.
     * @dev Iterates over the user's withdrawal requests to sum up the amounts that are eligible for claiming.
     * @param user The address of the user for whom the claimable amount is calculated.
     * @return totalClaimableAmount The total amount that can be claimed by the specified user.
     */
    function getTotalClaimableAmountByUser(address user) external view returns (uint256 totalClaimableAmount) {
        uint256 currentBlock = block.number;
        uint256 userIndex = withdrawalRequestIndex[user];
        // Iterate over each withdrawal request for the user
        for (uint256 j = 0; j < userIndex; ++j) {
            WithdrawalRequest memory request = withdrawalRequests[user][j];

            // Check if the request is eligible for claiming
            if (!request.processed && request.withdrawableBlockNumber <= currentBlock) {
                totalClaimableAmount += request.amount;
            }
        }

        return totalClaimableAmount;
    }

    function getWithdrawalRequest(address requester, uint256 index) external view returns (WithdrawalRequest memory) {
        WithdrawalRequest memory request = withdrawalRequests[requester][index];
        return request;
    }

    function getDepositManager() external view returns (address) {
        return depositManager;
    }

    function getSeigManager() external view returns (address) {
        return seigManager;
    }

    function getStakingIndex() external view returns (uint256) {
        return stakingIndex;
    }

    function getTonAddress() external view returns (address) {
        return ton;
    }

    function getWtonAddress() external view returns (address) {
        return wton;
    }

    function getLayer2Address() external view returns (address) {
        return layer2Address;
    }

    function getWithdrawalRequestIndex(address _user) external view returns (uint256) {
        return withdrawalRequestIndex[_user];
    }

    function getlastSeigBlock() external view returns (uint256) {
        return lastSeigBlock;
    }

    function getPaused() external view returns (bool) {
        return paused;
    }
}
