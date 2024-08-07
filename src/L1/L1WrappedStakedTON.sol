// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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

contract L1WrappedStakedTON is Ownable, ERC20 {
    using SafeERC20 for IERC20;


    struct StakingTracker {
        uint256 amount;
        address depositor;
        uint256 stakingIndex;
        uint256 depositTime;
        uint256 depositBlockNumber;
    }
    StakingTracker[] public stakingTrackers;

    bool paused;

    address public layer2Address;
    address public l1StandardBridge;
    address public WSTONVault;
    address public l2wston;
    address public l1wton;
    address public depositManager;
    address public seigManager;
    uint256 public totalAmountStaked;
    uint256 public lastRewardsDistributionDate;

    //deposit even
    event Deposited(address to, uint256 amount, uint256 depositTime, uint256 depositBlockNumber);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

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
        address _l1StandardBridge,
        address _l2wston,
        address _l1wton,
        address _depositManager,
        address _seigManager,
        uint256 _totalAmountStaked,
        uint256 _lastRewardsDistributionDate
    ) ERC20("Wrapped Staked TON", "WSTON") Ownable(msg.sender) {
        depositManager = _depositManager;
        seigManager = _seigManager;
        layer2Address = _layer2Address;
        l1StandardBridge = _l1StandardBridge;
        l2wston = _l2wston;
        l1wton = _l1wton;
        totalAmountStaked = _totalAmountStaked;
        lastRewardsDistributionDate = _lastRewardsDistributionDate;
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
        uint256 _amount
    ) external whenNotPaused {
        require(_depositAndGetWSTONTo(msg.sender, _amount), "failed to deposit and get WSTON");
    }

    function depositAndGetWSTONTo(
        address _to,
        uint256 _amount
    ) external whenNotPaused {
        require(_depositAndGetWSTONTo(_to, _amount), "failed to deposit and get WSTON");
    }

    function _depositAndGetWSTONTo(
        address _to,
        uint256 _amount
    ) internal returns (bool) {

        // user transfers wton to this contract
        require(
            IERC20(l1wton).transferFrom(_to, address(this), _amount),
            "failed to transfer wton to this contract"
        );

        // approve depositManager to spend on behalf of the WrappedStakedTON contract 
        IERC20(l1wton).approve(depositManager, _amount);

        // deposit _amount to DepositManager
        require(
            IDepositManager(depositManager).deposit(
                layer2Address,
                _amount
            ),
            "failed to stake"
        );

        StakingTracker memory _stakingTracker = StakingTracker({
            amount: _amount,
            depositor: _to,
            stakingIndex: 1,
            depositTime: block.timestamp,
            depositBlockNumber: block.number
        });
        stakingTrackers.push(_stakingTracker);

        // we mint WSTON
        _mint(_to, _amount);

        emit Deposited(_to, _amount, block.timestamp, block.number);

        return true;
    }



    function setL2wstonAddress(address _l2wston) external onlyOwner {
        l2wston = _l2wston;
    }

    function setl1StandardBridgeAddress(address _l1StandardBridge) external onlyOwner {
        l1StandardBridge = _l1StandardBridge;
    }

    function setDepositManagerAddress(address _depositManager) external onlyOwner {
        depositManager = _depositManager;
    }

    function setSeigManagerAddress(address _seigManager) external onlyOwner {
        seigManager = _seigManager;
    }

}
