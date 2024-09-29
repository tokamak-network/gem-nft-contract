// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { IDepositManager } from "../interfaces/IDepositManager.sol";
import { L1WrappedStakedTONStorage } from "./L1WrappedStakedTONStorage.sol";
import "../proxy/ProxyStorage.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ICandidate {
    function updateSeigniorage() external returns(bool);
}


contract L1WrappedStakedTON is Ownable, ERC20, ProxyStorage, L1WrappedStakedTONStorage, ReentrancyGuard {
    using SafeERC20 for IERC20; 

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor(
        address _layer2Address,
        address _wton,
        address _depositManager,
        address _seigManager,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        depositManager = _depositManager;
        seigManager = _seigManager;
        layer2Address = _layer2Address;
        wton = _wton;
        stakingIndex = DECIMALS;
    }

    function decimals() public view virtual override returns (uint8) {
        return 27;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function onApprove(
        address _to,
        uint256 _amount,
        bytes calldata data
    ) external returns (bool) {
        require(msg.sender == wton, "only accept WTON approve callback");

        (address to, uint256 amount) = _decodeDepositAndGetWSTONOnApproveData(data);
        require(to == _to && amount == _amount);
        require(_depositAndGetWSTONTo(to, amount));

        return true;
    }

    function _decodeDepositAndGetWSTONOnApproveData(bytes calldata data) internal pure returns(address to, uint256 amount) {
        require(data.length == 52, "Invalid onApprove data for L1WrappedStakedTON");
        assembly {
            // The layout of a "bytes calldata" is:
            // The first 20 bytes: to
            // The next 32 bytes: amount
            to := shr(96, calldataload(data.offset))
            amount := calldataload(add(data.offset, 20))
        }
    }

    function depositAndGetWSTON(
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        if(!_depositAndGetWSTONTo(msg.sender, _amount)) {
            revert DepositFailed();
        }
    }

    function depositAndGetWSTONTo(
        address _to,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        if(!_depositAndGetWSTONTo(_to, _amount)) {
            revert DepositFailed();
        }
    }

    /**
     * @dev Internal function to deposit WTON and mint WSTON for a specified address.
     * Transfers `_amount` of WTON to this contract, updates seigniorage, 
     * stakes the amount in the DepositManager, and mints WSTON.
     * @param _to The address that will receive the minted WSTON.
     * @param _amount The amount of WTON to be deposited and staked.
     * @return bool Returns true if the operation is successful.
     * Requirements:
     * - `_amount` must not be zero.
     * - `_to` must have allowed the contract to spend at least `_amount` of WTON.
     * - WTON transfer to this contract must succeed.
     * - Seigniorage update must succeed if necessary.
     * - Approval for depositManager to spend on behalf of this contract must succeed.
     * - Staking the amount in DepositManager must succeed.
     */
    function _depositAndGetWSTONTo(
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        
        if(_amount == 0) {
            revert WrontAmount();
        }
        // user transfers wton to this contract
        require(
            IERC20(wton).transferFrom(_to, address(this), _amount),
            "failed to transfer wton to this contract"
        );

        //we update seigniorage to get the latest sWTON balance
        if(lastSeigBlock != 0 && ISeigManager(seigManager).lastSeigBlock() < block.number) {
            require(ICandidate(layer2Address).updateSeigniorage(), "failed to update seigniorage");
        }
        lastSeigBlock = block.number;

        // updating the staking index
        stakingIndex = updateStakingIndex();
        emit StakingIndexUpdated(stakingIndex);

        // approve depositManager to spend on behalf of the WrappedStakedTON contract 
        IERC20(wton).approve(depositManager, _amount);

        // deposit _amount to DepositManager
        require(
            IDepositManager(depositManager).deposit(
                layer2Address,
                _amount
            ),
            "failed to stake"
        );
        
        // calculates the amount of WSTON to mint
        uint256 wstonAmount = getDepositWstonAmount(_amount);
        totalStakedAmount += _amount;

        // we mint WSTON
        _mint(_to, wstonAmount);
        totalWstonMinted += wstonAmount;

        emit Deposited(_to, _amount, wstonAmount, block.timestamp, block.number);

        return true;
    }

    function requestWithdrawal(uint256 _wstonAmount) external whenNotPaused {
        uint256 delay = IDepositManager(depositManager).getDelayBlocks(layer2Address);
        require(_requestWithdrawal(msg.sender, _wstonAmount, delay), "failed to request withdrawal");
    }

    function requestWithdrawalTo(address _to, uint256 _wstonAmount) external whenNotPaused {
        uint256 delay = IDepositManager(depositManager).getDelayBlocks(layer2Address);
        require(_requestWithdrawal(_to, _wstonAmount, delay), "failed to request withdrawal");       
    }

    function _requestWithdrawal(address _to, uint256 _wstonAmount, uint256 delay) internal returns (bool) {
        if(balanceOf(_to) < _wstonAmount) {
            revert NotEnoughFunds();
        }

        // updating the staking index
        stakingIndex = updateStakingIndex();
        emit StakingIndexUpdated(stakingIndex);

        uint256 _amountToWithdraw;
        _amountToWithdraw = (_wstonAmount * stakingIndex) / DECIMALS;

        require(
            IDepositManager(depositManager).requestWithdrawal(layer2Address, _amountToWithdraw),
            "failed to request withdrawal from the deposit manager"
        );

        withdrawalRequests[_to].push(WithdrawalRequest({
            withdrawableBlockNumber: block.number + delay,
            amount: _amountToWithdraw,
            processed: false
        }));

        // Burn wstonAmount
        _burn(_to, _wstonAmount);

        emit WithdrawalRequested(_to, _wstonAmount);
        return true;
    }

    function claimWithdrawalTo(address _to) external whenNotPaused {
        require(_claimWithdrawal(_to), "failed to claim");
    }

    function claimWithdrawal() external whenNotPaused {
        require(_claimWithdrawal(msg.sender), "failed to claim");
    }

    function _claimWithdrawal(address _to) internal returns(bool){
        uint256 index = withdrawalRequestIndex[_to];
        if(withdrawalRequests[_to].length <= index) {
            revert NoRequestToProcess();
        }

        WithdrawalRequest storage request = withdrawalRequests[_to][index];
        if(request.processed == true) {
            revert RequestAlreadyProcessed();
        }
        if(request.withdrawableBlockNumber > block.number) {
            revert WithdrawalDelayNotElapsed();
        }

        request.processed = true;
        unchecked {
            withdrawalRequestIndex[_to] += 1;
        }

        uint256 amount = request.amount;

        require(IDepositManager(depositManager).processRequest(layer2Address, false));

        IERC20(wton).safeTransfer(_to, amount);

        emit WithdrawalProcessed(_to, amount);
        return true;
    }

    function updateSeigniorage() external returns(bool) {
        require(ISeigManager(seigManager).updateSeigniorage());
        return true;
    }

    function updateStakingIndex() internal returns (uint256) {
        uint256 _stakingIndex;
        uint256 totalStake = stakeOf();
        
        if (totalWstonMinted > 0 && totalStake > 0) {
            // Multiply first to avoid precision loss, then divide
            _stakingIndex = (totalStake * DECIMALS) / totalWstonMinted;
        } else {
            _stakingIndex = stakingIndex;
        }
        
        stakingIndex = _stakingIndex;
        emit StakingIndexUpdated(_stakingIndex);
        return _stakingIndex;
    }

    function getDepositWstonAmount(uint256 _amount) internal view returns(uint256) {
        uint256 _wstonAmount = (_amount * DECIMALS) / stakingIndex;
        return _wstonAmount;
    }


    function setDepositManagerAddress(address _depositManager) external onlyOwner {
        depositManager = _depositManager;
    }

    function setSeigManagerAddress(address _seigManager) external onlyOwner {
        seigManager = _seigManager;
    }

    function stakeOf() public view returns(uint256) {
        return ISeigManager(seigManager).stakeOf(layer2Address, address(this));
    }

    function totalSupply() public view override returns(uint256) {
        return totalWstonMinted;
    }

    function getTotalWSTONSupply() external view returns(uint256) {return totalSupply();} 

    function getLastWithdrawalRequest(address requester) external view returns(WithdrawalRequest memory) {
        uint256 index = withdrawalRequestIndex[requester];
        WithdrawalRequest memory request = withdrawalRequests[requester][index];
        return request;
    }

    function getWithdrawalRequest(address requester, uint256 index) external view returns(WithdrawalRequest memory) {
        WithdrawalRequest memory request = withdrawalRequests[requester][index];
        return request;
    }

}
