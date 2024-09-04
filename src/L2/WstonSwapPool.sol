// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WstonSwapPool is Ownable, ReentrancyGuard {

    uint256 public constant DECIMALS = 10**27;
    uint256 public constant FEE_RATE_DIVIDER = 10000; // bps to percent

    address public ton;
    address public wston;
    address public treasury;

    uint256 public stakingIndex;
    uint256 public tonReserve;
    uint256 public wstonReserve;
    uint256 public feeRate; // in bps => 100 = 1%

    mapping(address => uint256) public lpShares;
    address[] public lpAddresses;
    uint256 public totalShares;

    event Swap(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event StakingIndexUpdated(uint256 newIndex);
    event LiquidityAdded(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event LiquidityRemoved(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event FeesCollected(uint256 tonFees, uint256 wstonFees);

    modifier onlyTreasury() {
        require(
            msg.sender == treasury, 
            "function callable from treasury contract only"
        );
        _;
    }

    constructor(address _ton, address _wston, uint256 _initialStakingIndex, address _treasury, uint256 _feeRate) Ownable(msg.sender) {
        ton = _ton;
        wston = _wston;
        treasury = _treasury;
        stakingIndex = _initialStakingIndex;
        feeRate = _feeRate;
    }

    function addLiquidity(uint256 tonAmount, uint256 wstonAmount) external nonReentrant {
        require(IERC20(ton).allowance(msg.sender, address(this)) >= tonAmount, "TON allowance too low");
        require(IERC20(wston).allowance(msg.sender, address(this)) >= wstonAmount, "WSTON allowance too low");
        require(IERC20(ton).balanceOf(msg.sender) >= tonAmount, "TON balance too low");
        require(IERC20(wston).balanceOf(msg.sender) >= wstonAmount, "WSTON balance too low");

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
        require(lpShares[msg.sender] >= shares, "Insufficient LP shares");

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
        require(IERC20(wston).allowance(msg.sender, address(this)) >= wstonAmount, "TON allowance too low");
        require(IERC20(wston).balanceOf(msg.sender) >= wstonAmount, "TON balance too low");

        uint256 tonAmount = ((wstonAmount * stakingIndex) / DECIMALS) / (10**9);
        uint256 fee = (tonAmount * feeRate) / FEE_RATE_DIVIDER;
        uint256 tonAmountToTransfer = tonAmount - fee;

        require(IERC20(ton).balanceOf(address(this)) >= tonAmount, "TON balance too low in pool");

        _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);
        _safeTransfer(IERC20(ton), msg.sender, tonAmountToTransfer);

        // Update reserves
        wstonReserve += wstonAmount;
        tonReserve -= tonAmount;

        _distributeFees(fee, 0);

        emit Swap(msg.sender, tonAmount, wstonAmount);
    }

    function swapTONforWSTON(uint256 tonAmount) external onlyTreasury {
        require(IERC20(ton).allowance(msg.sender, address(this)) >= tonAmount, "TON allowance too low");
        require(IERC20(ton).balanceOf(msg.sender) >= tonAmount, "TON balance too low");

        uint256 wstonAmount = (tonAmount * (10**9) * DECIMALS) / stakingIndex;
        uint256 fee = (wstonAmount * feeRate) / FEE_RATE_DIVIDER;
        uint256 wstonAmountToTransfer = wstonAmount - fee;

        require(IERC20(wston).balanceOf(address(this)) >= wstonAmount, "WSTON balance too low in pool");

        _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        _safeTransfer(IERC20(wston), msg.sender, wstonAmountToTransfer);

        // Update reserves
        tonReserve += tonAmount;
        wstonReserve -= wstonAmount;

        _distributeFees(0, fee);

        emit Swap(msg.sender, tonAmount, wstonAmount);
    }

    function updateStakingIndex(uint256 newIndex) external onlyOwner {
        require(newIndex >= 10**27, "staking index cannot be less than 1");
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

        for (uint256 i = 0; i < lpAddresses.length; i++) {
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

}