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

    constructor(
        address _layer2, 
        address _depositManager, 
        address _seigManager, 
        address _wton,
        address _titanwston,
        address _l1StandardBridge
    ) ERC20("Wrapped Staked TON", "WSTON") Ownable(msg.sender) {
        layer2 = _layer2;
        depositManager = _depositManager;
        seigManager = _seigManager;
        wton = _wton;
        titanwston = _titanwston;
        l1StandardBridge = _l1StandardBridge;
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

    function depositAndGetWSTON(uint256 _amount, address _recipient) external whenNotPaused nonReentrant returns (bool) {
        // user transfers wton to this contract
        require(IERC20(wton).transferFrom(_recipient, address(this), _amount), "failed to transfer wton to this contract");
        // deposit _amount to DepositManager
        require(IDepositManager(depositManager).deposit(layer2, _amount), "failed to stake");

        // we mint WSTON 
        _mint(address(this), _amount);

        uint256 wstonAllowance = allowance(address(this), l1StandardBridge);
        if(wstonAllowance < _amount) approve(l1StandardBridge, _amount-wstonAllowance);

        uint256 balanceBefore = balanceOf(l1StandardBridge); 

        DepositTracker memory _depositTracker = DepositTracker({
            stakingIndex: depositTrackers.length,
            depositTime: block.timestamp
        });

        depositTrackers.push(_depositTracker);

        bytes memory data = abi.encode(_depositTracker);

        // Bridge WSTON to L2
        IL1StandardBridge(l1StandardBridge).depositERC20To(
            address(this), 
            titanwston, 
            _recipient, 
            _amount, 
            MIN_DEPOSIT_GAS_LIMIT, 
            data
        );

        require(balanceOf(l1StandardBridge) == balanceBefore + _amount, "fail depositERC20To");

        emit Deposited(_recipient, _amount);
        return true;
    }

    function updateSeigniorage() external whenNotPaused {
        ISeigManager(seigManager).updateSeigniorage();
    }

}
