// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { ISeigManager } from "../interfaces/ISeigManager.sol";
import { IDepositManager } from "../interfaces/IDepositManager.sol";
import { IRefactorCoinageSnapshot } from "../interfaces/IRefactorCoinageSnapshot.sol";
import { IRefactor } from "../interfaces/IRefactor.sol";
import { WrappedStakedTONStorage } from "./WrappedStakedTONStorage.sol";
import { DSMath } from "../libraries/DSMath.sol";



contract WrappedStakedTON is ReentrancyGuard, Ownable, ERC20, WrappedStakedTONStorage, DSMath {

    using SafeERC20 for IERC20;
    

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }


    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    constructor(address _layer2, address _depositManager, address _seigManager, address _wton) ERC20("Wrapped Staked TON", "WSTON") Ownable(msg.sender) {
        layer2 = _layer2;
        depositManager = _depositManager;
        seigManager = _seigManager;
        wton = _wton;
        factor = IRefactorCoinageSnapshot(_layer2).factor();
    }

    function decimals() public view virtual override returns (uint8) {
        return 27;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenNotPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function depositAndGetWSTON(uint256 _amount) external whenNotPaused nonReentrant returns (bool) {
        // we transfer wton to this contract
        require(IERC20(wton).transferFrom(msg.sender, address(this), _amount), "failed ton transfer wton to this contract");
        require(IDepositManager(depositManager).deposit(layer2, _amount), "failed to deposit");

        // user deposits storage update
        balances[msg.sender].balance += _amount;
        
        
        // staking index update

        // we mint WSTON
        _mint(msg.sender, _amount);
        emit Deposited(msg.sender, _amount);
        return true;
    }

    function requestTONWithdrawal(uint256 _amount) external whenNotPaused nonReentrant returns (bool) {
        require(balances[msg.sender].balance >= _amount, "not enough funds");
        require(IDepositManager(depositManager).requestWithdrawal(layer2, _amount), "failed to request withdrawal");

        emit WithdrawalRequested(msg.sender, _amount);
        return true;
    }

    function updateSeigniorage() external whenNotPaused {
        ISeigManager(seigManager).updateSeigniorage();
        
        // not sure if correct
        for (uint256 i = 0; i < balanceAddresses.length; i++) {
            address addr = balanceAddresses[i];
            balances[addr].refactoredCount += 1;
        }
    }

    function usersTONBalance(address _account) external view returns (uint256) {
        IRefactor.Balance storage b = balances[_account];

        return _applyFactor(b.balance, b.refactoredCount);
    }

    function _applyFactor(uint256 v, uint256 refactoredCount) internal view returns (uint256) {
        if (v == 0) {
            return 0;
        }
        v = rmul2(v, factor);
        uint256 WSTONrefactorCount = getWSWTONRefactorCount();
        if (WSTONrefactorCount > refactoredCount) {
            v = v * REFACTOR_DIVIDER ** (WSTONrefactorCount - refactoredCount);
        }
        return v;
    }

    function getWSWTONRefactorCount() internal view returns (uint256) {
        (IRefactor.Balance memory WSTONBalance, ) = IRefactorCoinageSnapshot(layer2).getBalanceAndFactor(address(this));
        return WSTONBalance.refactoredCount;
    }


}
