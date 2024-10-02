// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AuthControl} from "../common/AuthControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../proxy/ProxyStorage.sol";

import { WstonSwapPoolStorage } from "./WstonSwapPoolStorage.sol";

contract WstonSwapPool is ProxyStorage, AuthControl, ReentrancyGuard, WstonSwapPoolStorage {

    modifier onlyTreasury() {
        require(
            msg.sender == treasury, 
            "function callable from treasury contract only"
        );
        _;
    }

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

        _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);

        if (lpShares[msg.sender] == 0) {
            lpAddresses.push(msg.sender);
        }

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

        if(IERC20(ton).balanceOf(address(this)) < tonAmount) {
            revert ContractTonBalanceTooLow();
        }

        _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);
        _safeTransfer(IERC20(ton), msg.sender, tonAmountToTransfer);

        // Update reserves
        wstonReserve += wstonAmount;
        tonReserve -= tonAmount;

        _distributeFees(fee, 0);

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

        if(IERC20(wston).balanceOf(address(this)) < wstonAmount) {
            revert ContractWstonBalanceTooLow();
        }

        _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        _safeTransfer(IERC20(wston), msg.sender, wstonAmountToTransfer);

        // Update reserves
        tonReserve += tonAmount;
        wstonReserve -= wstonAmount;

        _distributeFees(0, fee);

        emit SwappedTonForWston(msg.sender, tonAmount, wstonAmount);
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

    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function _safeTransfer(IERC20 token, address recipient, uint256 amount) private {
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }

   function _distributeFees(uint256 tonFees, uint256 wstonFees) private {
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

        emit FeesCollected(tonFees, wstonFees);
    }


    function getLpShares(address lp) external view returns (uint256) {
        return lpShares[lp];
    }

    function getWstonReserve() external view returns(uint256) {
        return wstonReserve;
    }

    function getTonReserve() external view returns(uint256) {
        return tonReserve;
    }

    function getTotalShares() external view returns(uint256) {
        return totalShares;
    }

    function getStakingIndex() external view returns(uint256) {
        return stakingIndex;
    }

}