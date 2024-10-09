// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AuthControl} from "../common/AuthControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../proxy/ProxyStorage.sol";

import { WstonSwapPoolStorage } from "./WstonSwapPoolStorage.sol";

contract WstonSwapPool is ProxyStorage, AuthControl, ReentrancyGuard, WstonSwapPoolStorage {

    modifier whenNotPaused() {
      require(!paused, "Pausable: paused");
      _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }
    
    modifier onlyTreasury() {
        require(
            msg.sender == treasury, 
            "function callable from treasury contract only"
        );
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenNotPaused {
        paused = false;
    }

    /**
     * @notice Initializes the WstonSwapPool contract with the given parameters.
     * @param _ton The address of the TON token contract.
     * @param _wston The address of the WSTON token contract.
     * @param _initialStakingIndex The initial staking index value.
     * @param _treasury The address of the treasury contract.
     * @param _feeRate The fee rate for swaps.
     * @dev Can only be called once. Grants the caller the default admin role.
     */
    function initialize(
        address _ton, 
        address _wston,
        uint256 _initialStakingIndex, 
        address _treasury, 
        uint256 _feeRate
    ) external {
        require(!initialized, "already initialized");   
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ton = _ton;
        wston = _wston;
        treasury = _treasury;
        stakingIndex = _initialStakingIndex;
        feeRate = _feeRate;
        initialized = true;
    }

    //---------------------------------------------------------------------------------------
    //--------------------------------EXTERNAL FUNCTIONS-------------------------------------
    //---------------------------------------------------------------------------------------

    /**
     * @notice Adds liquidity to the pool by depositing TON and/or WSTON tokens.
     * @param tonAmount The amount of TON tokens to deposit.
     * @param wstonAmount The amount of WSTON tokens to deposit.
     * @dev Requires the caller to have approved the contract to spend the specified amounts.
     *      Emits a {LiquidityAdded} event.
     */
    function addLiquidity(uint256 tonAmount, uint256 wstonAmount) external nonReentrant {
        if(IERC20(ton).allowance(msg.sender, address(this)) < tonAmount) {
            revert TonAllowanceTooLow();
        }
        if(IERC20(wston).allowance(msg.sender, address(this)) < wstonAmount) {
            revert WstonAllowanceTooLow();
        }
        if(IERC20(ton).balanceOf(msg.sender) < tonAmount) {
            revert TonBalanceTooLow();
        }
        if(IERC20(wston).balanceOf(msg.sender) < wstonAmount) {
            revert WstonBalanceTooLow();
        }
        if(tonAmount == 0 && wstonAmount == 0) {
            revert WrongAmounts();
        }

        // transfer the funds to the contract
        if(tonAmount > 0) {
            _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        }
        if( wstonAmount > 0) {
            _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);
        }

        // storing the LP address if it does not exist. The condition prevent from DoS the lpAddresses array
        if (lpShares[msg.sender] == 0) {
            lpAddresses.push(msg.sender);
        }

        // shares storage update 
        uint256 shares = tonAmount + (wstonAmount / (10**9));
        lpShares[msg.sender] += shares;
        totalShares += shares;

        tonReserve += tonAmount;
        wstonReserve += wstonAmount;

        emit LiquidityAdded(msg.sender, tonAmount, wstonAmount);
    }

    function removeLiquidity(uint256 shares) external nonReentrant {
        if(lpShares[msg.sender] < shares) {
            revert InsufficientLpShares();
        }

        uint256 tonAmount = (shares * tonReserve) / totalShares;
        uint256 wstonAmount = (shares * wstonReserve) / totalShares;

        lpShares[msg.sender] -= shares;
        totalShares -= shares;

        tonReserve -= tonAmount;
        wstonReserve -= wstonAmount;

        _safeTransfer(IERC20(ton), msg.sender, tonAmount);
        _safeTransfer(IERC20(wston), msg.sender, wstonAmount);

        emit LiquidityRemoved(msg.sender, tonAmount, wstonAmount);
    }


    function swapWSTONforTON(uint256 wstonAmount) external nonReentrant {
        if(IERC20(wston).allowance(msg.sender, address(this)) < wstonAmount) {
            revert WstonAllowanceTooLow();
        }
        if(IERC20(wston).balanceOf(msg.sender) < wstonAmount) {
            revert TonBalanceTooLow();
        }

        uint256 tonAmount = ((wstonAmount * stakingIndex) / DECIMALS) / (10**9);
        uint256 fee = (tonAmount * feeRate) / FEE_RATE_DIVIDER;
        uint256 tonAmountToTransfer = tonAmount - fee;

        tonFeeBalance += fee;

        if(IERC20(ton).balanceOf(address(this)) < tonAmount) {
            revert ContractTonBalanceTooLow();
        }

        _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);
        _safeTransfer(IERC20(ton), msg.sender, tonAmountToTransfer);

        // Update reserves
        wstonReserve += wstonAmount;
        tonReserve -= tonAmount;

        emit SwappedWstonForTon(msg.sender, tonAmount, wstonAmount);
    }

    function swapTONforWSTON(uint256 tonAmount) external onlyTreasury {
        if(IERC20(ton).allowance(msg.sender, address(this)) < tonAmount) {
            revert TonAllowanceTooLow();
        }
        if(IERC20(ton).balanceOf(msg.sender) < tonAmount) {
            revert TonBalanceTooLow();
        }

        uint256 wstonAmount = (tonAmount * (10**9) * DECIMALS) / stakingIndex;
        uint256 fee = (wstonAmount * feeRate) / FEE_RATE_DIVIDER;
        uint256 wstonAmountToTransfer = wstonAmount - fee;

        wstonFeeBalance += fee;

        if(IERC20(wston).balanceOf(address(this)) < wstonAmount) {
            revert ContractWstonBalanceTooLow();
        }

        _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        _safeTransfer(IERC20(wston), msg.sender, wstonAmountToTransfer);

        // Update reserves
        tonReserve += tonAmount;
        wstonReserve -= wstonAmount;

        emit SwappedTonForWston(msg.sender, tonAmount, wstonAmount);
    }

    /**
     * @notice Distributes accumulated TON and WSTON fees to liquidity providers based on their share.
     * @dev This function iterates over all liquidity providers and distributes fees proportionally.
     *      It resets the fee balances before distribution to prevent reentrancy attacks.
     *      Ensure that the function is called when there are fees to distribute to avoid unnecessary gas costs.
     * @dev Emits a {FeesDistributed} event.
     * @dev Uses the nonReentrant modifier to prevent reentrancy attacks.
     */
    function distributeFees() external nonReentrant {
        uint256 tonFees = tonFeeBalance;
        uint256 wstonFees = wstonFeeBalance;
        require(tonFees > 0 || wstonFees > 0, "No fees to claim");

        // reset storage variables before transferring
        tonFeeBalance = 0;
        wstonFeeBalance = 0;

        if (totalShares == 0) return;

        for (uint256 i = 0; i < lpAddresses.length; ++i) {
            address lp = lpAddresses[i];
            uint256 share = lpShares[lp];
            if (share > 0) {
                uint256 tonReward = (tonFees * share) / totalShares;
                uint256 wstonReward = (wstonFees * share) / totalShares;

                if (tonReward > 0) {
                    _safeTransfer(IERC20(ton), lp, tonReward);
                }
                if (wstonReward > 0) {
                    _safeTransfer(IERC20(wston), lp, wstonReward);
                }
            }
        }

        emit FeesDistributed(tonFees, wstonFees);
    }

    function updateStakingIndex(uint256 newIndex) external onlyOwner {
        if(newIndex < 10**27) {
            revert WrongStakingIndex();
        }
        stakingIndex = newIndex;
        emit StakingIndexUpdated(newIndex);
    }

    function updateFeeRate(uint256 _feeRate) external onlyOwner {
        feeRate = _feeRate;
    }

    //---------------------------------------------------------------------------------------
    //-----------------------------INTERNAL/PRIVATE FUNCTIONS--------------------------------
    //---------------------------------------------------------------------------------------

    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function _safeTransfer(IERC20 token, address recipient, uint256 amount) private {
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }

    //---------------------------------------------------------------------------------------
    //------------------------STORAGE GETTER / VIEW FUNCTIONS--------------------------------
    //---------------------------------------------------------------------------------------

    function getLpShares(address lp) external view returns (uint256) {return lpShares[lp];}
    function getWstonReserve() external view returns(uint256) { return wstonReserve;}
    function getTonReserve() external view returns(uint256) {return tonReserve;}
    function getTotalShares() external view returns(uint256) {return totalShares;}
    function getStakingIndex() external view returns(uint256) {return stakingIndex;}
    function getTonFeesBalance() external view returns (uint256) {return tonFeeBalance;}
    function getWstonFeesBalance() external view returns (uint256) {return wstonFeeBalance;}

}