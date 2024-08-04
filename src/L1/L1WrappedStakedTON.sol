// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { IDepositManager } from "../interfaces/IDepositManager.sol";
import { L1WrappedStakedTONStorage } from "./L1WrappedStakedTONStorage.sol";

interface IL1StandardBridge {
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface IL1CrossDomainMessenger {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

contract L1WrappedStakedTON is ReentrancyGuard, Ownable, ERC20, L1WrappedStakedTONStorage {
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
        Layer2[] memory _layer2s,
        uint256 _minDepositAmount,
        address _depositManager,
        address _seigManager,
        address _l1wton
    ) ERC20("Wrapped Staked TON", "WSTON") Ownable(msg.sender) {
        for (uint256 i = 0; i < _layer2s.length; i++) {
            layer2s.push(_layer2s[i]);
        }
        depositManager = _depositManager;
        seigManager = _seigManager;
        l1wton = _l1wton;
        minDepositAmount = _minDepositAmount;
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

    function depositAndGetWSTON(
        uint256 _amount,
        uint256 _layer2Index
    ) external whenNotPaused nonReentrant {
        require(_depositAndGetWSTONTo(msg.sender, _amount, _layer2Index), "failed to deposit and get WSTON");
    }

    function depositAndGetWSTONTo(
        address _to,
        uint256 _amount,
        uint256 _layer2Index
    ) external whenNotPaused nonReentrant {
        require(_depositAndGetWSTONTo(_to, _amount, _layer2Index), "failed to deposit and get WSTON");
    }

    function _depositAndGetWSTONTo(
        address _to,
        uint256 _amount,
        uint256 _layer2Index
    ) internal returns (bool) {

        require(_amount >= minDepositAmount, "min required amount");

        // user transfers wton to this contract
        require(
            IERC20(l1wton).transferFrom(_to, address(this), _amount),
            "failed to transfer wton to this contract"
        );

        // approve depositManager to spend on behalf of the WrappedStakedTON coontract 
        IERC20(l1wton).approve(depositManager, _amount);

        // deposit _amount to DepositManager
        require(
            IDepositManager(depositManager).deposit(
                layer2s[_layer2Index].layer2Address,
                _amount
            ),
            "failed to stake"
        );

        StakingTracker memory _stakingTracker = StakingTracker({
            layer2: layer2s[_layer2Index],
            amount: _amount,
            stakingIndex: stakingTrackerCount,
            depositTime: block.timestamp
        });
        stakingTrackers.push(_stakingTracker);
        stakingTrackerCount++;

        userBalanceByStakingIndex[_to][_stakingTracker.stakingIndex] = _amount;

        // we mint WSTON
        _mint(_to, _amount);

        emit Deposited(stakingTrackerCount, _to, _amount, block.timestamp);

        return true;
    }

    function bridgeWSTON(uint256 _layer2Index, uint256 _stakingIndex, uint256 _amount) external nonReentrant whenNotPaused {
        require(_bridgeWSTONTo(_layer2Index, msg.sender, _stakingIndex, _amount));
    }

    function bridgeWSTONTo(uint256 _layer2Index, address _to, uint256 _stakingIndex, uint256 _amount) external nonReentrant whenNotPaused {
        require(_bridgeWSTONTo(_layer2Index, _to, _stakingIndex, _amount));
    }

    function _bridgeWSTONTo(uint256 _layer2Index, address _to, uint256 _stakingIndex, uint256 _amount) internal returns(bool) {
        address layer2Address = layer2s[_layer2Index].layer2Address;
        require(layer2Address != address(0));

        require(this.transferWSTONFrom(_stakingIndex, _to, address(this), _amount));
        userBridgedAmountByLayer2AndIndex[_to][_layer2Index][_stakingIndex] += _amount;

        IL1StandardBridge(layer2Address).depositERC20To(
            address(this),
            layer2s[_layer2Index].l2wston,
            _to,
            _amount,
            MIN_DEPOSIT_GAS_LIMIT,
            ""
        );

        emit WSTONBridged(_layer2Index, _to, _stakingIndex, _amount);
        return true;
    }

    function transferWSTONFrom(
        uint256 _stakingIndex, 
        address _from, 
        address _to, 
        uint256 _amount
    ) external nonReentrant returns(bool) {
        require(_to != address(0), "address zero");
        require(_amount >= 0, "zero amount");
        require(userBalanceByStakingIndex[_from][_stakingIndex] >= _amount, "not enough funds to transfer on this stakingIndex");

        // Check allowance
        require(allowance(_from, address(this)) >= _amount, "allowance too low");

        userBalanceByStakingIndex[_from][_stakingIndex] -= _amount;
        userBalanceByStakingIndex[_to][_stakingIndex] -= _amount;

        // Call transferFrom on behalf of the contract
        this.transferFrom(_from, _to, _amount);

        emit Transferred(_stakingIndex, _from, _to, _amount);
        return true;
    }

    function transferWSTON(uint256 _stakingIndex, address _to, uint256 _amount) external nonReentrant returns (bool) {
        require(_to != address(0), "address zero");
        require(_amount >= 0, "zero amount");
        require(userBalanceByStakingIndex[msg.sender][_stakingIndex] >= _amount, "not enough funds to transfer on this stakingIndex");

        userBalanceByStakingIndex[msg.sender][_stakingIndex] -= _amount;
        userBalanceByStakingIndex[_to][_stakingIndex] -= _amount;

        // Call transfer on behalf of the contract
        this.transfer(_to, _amount);

        emit Transferred(_stakingIndex, msg.sender, _to, _amount);
        return true;
    }

    function updateSeigniorage() external whenNotPaused {
        ISeigManager(seigManager).updateSeigniorage();
    }

    function addLayer2(
        address _layer2Address,
        address _l1StandardBridge,
        address _l1CrossDomainMessenger,
        address _WSTONManager,
        address _l2wston
    ) external onlyOwner returns (bool) {
        Layer2 memory layer2 = Layer2({
            layer2Address: _layer2Address,
            l1StandardBridge: _l1StandardBridge,
            l1CrossDomainMessenger: _l1CrossDomainMessenger,
            WSTONManager: _WSTONManager,
            l2wston: _l2wston
        });
        layer2s.push(layer2);
        return true;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
    }

    function getMinDepositAmount() external view returns(uint256) {
        return minDepositAmount;
    }

    // Override ERC20 transfer and transferFrom functions to disable user transferring anywher else from beside this contract
    function transfer(address to, uint256 value) public override returns (bool) {
        for(uint256 i = 0; i < layer2s.length; i++) {
            if(msg.sender != address(this) && msg.sender != layer2s[i].l1StandardBridge) {
                revert("Use transferWSTONFrom instead");
            }
        }

        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        for(uint256 i = 0; i < layer2s.length; i++) {
            if(msg.sender != address(this) && msg.sender != layer2s[i].l1StandardBridge) {
                revert("Use transferWSTONFrom instead");
            }
        }

        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
    

    // Todo requestWithdrawal, process withdrawal
}
