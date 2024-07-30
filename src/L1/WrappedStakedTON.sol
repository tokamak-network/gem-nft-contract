// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { IDepositManager } from "../interfaces/IDepositManager.sol";
import { WrappedStakedTONStorage } from "./WrappedStakedTONStorage.sol";

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

interface IWSTONManager {
    function onWSTONDeposit(
        address _recipient,
        uint256 _amount,
        uint256 _stakingIndex,
        uint256 _depositTime
    ) external;
}

contract WrappedStakedTON is ReentrancyGuard, Ownable, ERC20, WrappedStakedTONStorage {
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

    function depositAndGetWSTONOnL2(
        uint256 _amount,
        address _recipient,
        uint8 _layer2Index
    ) external whenNotPaused nonReentrant returns (bool) {
        // user transfers wton to this contract
        require(
            IERC20(l1wton).transferFrom(_recipient, address(this), _amount),
            "failed to transfer wton to this contract"
        );
        // deposit _amount to DepositManager
        require(
            IDepositManager(depositManager).deposit(
                layer2s[_layer2Index].layer2Address,
                _amount
            ),
            "failed to stake"
        );

        // we mint WSTON
        _mint(address(this), _amount);

        uint256 balanceBefore = balanceOf(
            layer2s[_layer2Index].l1StandardBridge
        );

        StakingTracker memory _stakingTracker = StakingTracker({
            holderId: 0,
            amount: _amount,
            stakingIndex: stakingTrackers.length,
            depositTime: block.timestamp
        });

        stakingTrackers.push(_stakingTracker);

        bytes memory data = abi.encode(_stakingTracker);

        // Bridge WSTON to L2
        IL1StandardBridge(layer2s[_layer2Index].l1StandardBridge)
            .depositERC20To(
                address(this),
                layer2s[_layer2Index].l2wston,
                layer2s[_layer2Index].WSTONManager,
                _amount,
                MIN_DEPOSIT_GAS_LIMIT,
                data
            );

        IL1CrossDomainMessenger(layer2s[_layer2Index].l1CrossDomainMessenger)
            .sendMessage(
                layer2s[_layer2Index].WSTONManager,
                abi.encodeCall(
                    IWSTONManager(layer2s[_layer2Index].WSTONManager).onWSTONDeposit,
                    (
                        _recipient,
                        _stakingTracker.amount,
                        _stakingTracker.stakingIndex,
                        _stakingTracker.depositTime
                    )
                ),
                1000000 // gas limit
            );

        require(
            balanceOf(layer2s[_layer2Index].l1StandardBridge) ==
                balanceBefore + _amount,
            "fail depositERC20To"
        );

        emit DepositedAndBridged(_recipient, _amount);
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

    // Todo requestWithdrawal, process withdrawal
}
