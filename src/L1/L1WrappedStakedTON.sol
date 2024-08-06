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

contract L1WrappedStakedTON is ReentrancyGuard, Ownable, ERC20, L1WrappedStakedTONStorage {
    using SafeERC20 for IERC20;

    // Flag to indicate if the bridgeWSTON function is being executed
    bool private isBridging;

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
        isBridging = false;
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
        // minimum deposits enabled in order to avoid user griefing the function
        require(_amount >= minDepositAmount, "min required amount");
        // we distribute rewards each time a user deposits in order to calculate each user's share correctly
        require(distributeRewards(), "failed to distrribute rewards");

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
                layer2s[_layer2Index].layer2Address,
                _amount
            ),
            "failed to stake"
        );

        StakingTracker memory _stakingTracker = StakingTracker({
            layer2: layer2s[_layer2Index],
            amount: _amount,
            depositor: _to,
            depositBlock: block.timestamp,
            depositTime: block.timestamp
        });
        stakingTrackers.push(_stakingTracker);
        stakingTrackerCount++;


        // mapping updates
        layer2s[_layer2Index].totalAmountStaked += _amount;
        userBalanceByLayer2Index[_to][_layer2Index] += _amount;
        
        // add user to the list if it is the first time he calls the function
        addUserAddress(_to);

        // recompute each staker's share rate
        uint256 totalStakedAmount = layer2s[_layer2Index].totalAmountStaked;
        for(uint256 i = 0; i < userAddresses.length; i++) {
            uint256 userBalance = userBalanceByLayer2Index[userAddresses[i]][_layer2Index];
            uint256 userShares = (userBalance * 1e27) / totalStakedAmount; // Multiply by 1e27 for precision
            userSharesByLayer2Index[_to][_layer2Index] = userShares;
        }

        // we mint WSTON
        _mint(_to, _amount);

        emit Deposited(stakingTrackerCount, _to, _amount, block.timestamp);
        return true;
    }

    /**
     * @notice function used to distribute the seigniorage received by the contract to each WSTON holder.
     */
    function distributeRewards() public whenNotPaused nonReentrant returns(bool) {   
        uint256 swtonContractBalance;
        require(ISeigManager(seigManager).updateSeigniorage(), "failed to update seigniorage");

        for(uint256 i = 0; i < layer2s.length; i++) {
            swtonContractBalance = ISeigManager(seigManager).stakeOf(layer2s[i].layer2Address, address(this));
            uint256 rewardsToDistribute = layer2s[i].totalAmountStaked - swtonContractBalance;
            if (rewardsToDistribute > 0) {
                for(uint256 j = 0; j < userAddresses.length; j++) {
                    uint256 userRewards = rewardsToDistribute * userSharesByLayer2Index[userAddresses[j]][i];
                    if(userRewards > 0) {
                        _mint(userAddresses[j], userRewards);   
                    }                    
                }

                layer2s[i].totalAmountStaked = swtonContractBalance;
                layer2s[i].lastRewardsDistributionDate = block.timestamp;
            }
        }
        return true;
    }

    function bridgeWSTON(uint256 _layer2Index, uint256 _amount) external nonReentrant whenNotPaused {
        require(_bridgeWSTONTo(_layer2Index, msg.sender, _amount));
    }

    function bridgeWSTONTo(uint256 _layer2Index, address _to, uint256 _amount) external nonReentrant whenNotPaused {
        require(_bridgeWSTONTo(_layer2Index, _to, _amount));
    }

    function _bridgeWSTONTo(uint256 _layer2Index, address _to, uint256 _amount) internal returns(bool) {
        address layer2Address = layer2s[_layer2Index].layer2Address;
        require(layer2Address != address(0));

        require(this.transferWSTONFrom(_layer2Index, _to, address(this), _amount));

        // flag to ensure user can't bridge without going through this function
        isBridging = true;

        IL1StandardBridge(layer2Address).depositERC20To(
            address(this),
            layer2s[_layer2Index].l2wston,
            layer2s[_layer2Index].WSTONVault,
            _amount,
            MIN_DEPOSIT_GAS_LIMIT,
            ""
        );

        isBridging = false;

        bridgedAmountByLayer2Index[layer2s[_layer2Index].WSTONVault][_layer2Index] += _amount;

        emit WSTONBridged(_layer2Index, _to, _amount);
        return true;
    }

    function transferWSTONFrom(
        uint256 _layer2Index, 
        address _from, 
        address _to, 
        uint256 _amount
    ) external nonReentrant returns(bool) {
        require(_to != address(0), "address zero");
        require(_amount >= 0, "zero amount");
        require(userBalanceByLayer2Index[_from][_layer2Index] >= _amount, "not enough funds to transfer on this stakingIndex");
        require(distributeRewards(), "failed to distrribute rewards");
        // Check allowance
        require(allowance(_from, address(this)) >= _amount, "allowance too low");

        uint256 fromOldBalance = userBalanceByLayer2Index[_from][_layer2Index];
        uint256 sharesTransferred = (userSharesByLayer2Index[_from][_layer2Index] * _amount) / fromOldBalance;
       
        userBalanceByLayer2Index[_from][_layer2Index] -= _amount;
        userBalanceByLayer2Index[_to][_layer2Index] += _amount;

        userSharesByLayer2Index[_from][_layer2Index] -= sharesTransferred;
        userSharesByLayer2Index[_to][_layer2Index] += sharesTransferred;

        if(userBalanceByLayer2Index[_from][_layer2Index] == 0) {
            delete userBalanceByLayer2Index[_from][_layer2Index];
            delete userSharesByLayer2Index[_from][_layer2Index];
        }

        // Call transferFrom on behalf of the contract
        this.transferFrom(_from, _to, _amount);

        emit Transferred(_layer2Index, _from, _to, _amount);
        return true;
    }

    function transferWSTON(uint256 _layer2Index, address _to, uint256 _amount) external nonReentrant returns (bool) {
        require(_to != address(0), "address zero");
        require(_amount >= 0, "zero amount");
        require(userBalanceByLayer2Index[msg.sender][_layer2Index] >= _amount, "not enough funds to transfer on this stakingIndex");
        require(distributeRewards(), "failed to distrribute rewards");

        uint256 fromOldBalance = userBalanceByLayer2Index[msg.sender][_layer2Index];
        uint256 sharesTransferred = (userSharesByLayer2Index[msg.sender][_layer2Index] * _amount) / fromOldBalance;
    
        
        userBalanceByLayer2Index[msg.sender][_layer2Index] -= _amount;
        userBalanceByLayer2Index[_to][_layer2Index] += _amount;

        userSharesByLayer2Index[msg.sender][_layer2Index] -= sharesTransferred;
        userSharesByLayer2Index[_to][_layer2Index] += sharesTransferred;

        if(userBalanceByLayer2Index[msg.sender][_layer2Index] == 0) {
            delete userBalanceByLayer2Index[msg.sender][_layer2Index];
            delete userSharesByLayer2Index[msg.sender][_layer2Index];
        }

        // Call transfer on behalf of the contract
        this.transfer(_to, _amount);

        emit Transferred(_layer2Index, msg.sender, _to, _amount);
        return true;
    }


    function addLayer2(
        address _layer2Address,
        address _l1StandardBridge,
        address _WSTONVault,
        address _l2wston
    ) external onlyOwner returns (bool) {
        Layer2 memory layer2 = Layer2({
            layer2Address: _layer2Address,
            l1StandardBridge: _l1StandardBridge,
            WSTONVault: _WSTONVault,
            l2wston: _l2wston,
            totalAmountStaked: 0,
            lastRewardsDistributionDate: block.timestamp
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
            if(msg.sender != address(this)) {
                revert("Not allowed to use transfer. Use transferWSTON instead");
            }
        }

        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        for(uint256 i = 0; i < layer2s.length; i++) {
            if(msg.sender != address(this) || (msg.sender != layer2s[i].l1StandardBridge && isBridging == true)) {
                revert("Not allowed to use transferFrom. Use transferWSTONFrom instead");
            }
        }

        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function addUserAddress(address user) internal {
        if (!userAddressExists[user]) {
            userAddresses.push(user);
            userAddressExists[user] = true;
        }
    }
    

    // Todo requestWithdrawal, process withdrawal
}
