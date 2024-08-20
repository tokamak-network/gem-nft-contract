// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WstonSwapPool is Ownable {

    uint256 public constant DECIMALS = 10**27;
    uint256 public constant FEE_RATE = 3; // 0.3% fee

    address public ton;
    address public wston;
    address public treasury;

    uint256 public stakingIndex;
    uint256 public tonReserve;
    uint256 public wstonReserve;

    mapping(address => uint256) public lpShares;
    address[] public lpAddresses;
    uint256 public totalShares;

    event Swap(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event StakingIndexUpdated(uint256 newIndex);
    event LiquidityAdded(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event FeesCollected(uint256 tonFees, uint256 wstonFees);

    modifier onlyTreasury() {
        require(
            msg.sender == treasury, 
            "function callable from treasury contract only"
        );
        _;
    }

    constructor(address _ton, address _wston, uint256 _initialStakingIndex, address _treasury) Ownable(msg.sender) {
        ton = _ton;
        wston = _wston;
        treasury = _treasury;
        stakingIndex = _initialStakingIndex;
    }

    function addLiquidity(uint256 tonAmount, uint256 wstonAmount) external {
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

    function swapWSTONforTON(uint256 wstonAmount) external {
        require(IERC20(wston).allowance(msg.sender, address(this)) >= wstonAmount, "TON allowance too low");
        require(IERC20(wston).balanceOf(msg.sender) >= wstonAmount, "TON balance too low");

        uint256 tonAmount = ((wstonAmount * stakingIndex) / DECIMALS) / (10**9);
        uint256 fee = (tonAmount * FEE_RATE) / 1000;
        tonAmount -= fee;

        require(IERC20(ton).balanceOf(address(this)) >= tonAmount, "TON balance too low in pool");

        _safeTransferFrom(IERC20(wston), msg.sender, address(this), wstonAmount);
        _safeTransfer(IERC20(ton), msg.sender, tonAmount);

        _distributeFees(fee, 0);

        emit Swap(msg.sender, tonAmount, wstonAmount);
    }

    function swapTONforWSTON(uint256 tonAmount) external onlyTreasury {
        require(IERC20(ton).allowance(msg.sender, address(this)) >= tonAmount, "TON allowance too low");
        require(IERC20(ton).balanceOf(msg.sender) >= tonAmount, "TON balance too low");

        uint256 wstonAmount = (tonAmount * (10**9) * DECIMALS) / stakingIndex;
        uint256 fee = (wstonAmount * FEE_RATE) / 1000;
        wstonAmount -= fee;

        require(IERC20(wston).balanceOf(address(this)) >= wstonAmount, "WSTON balance too low in pool");

        _safeTransferFrom(IERC20(ton), msg.sender, address(this), tonAmount);
        _safeTransfer(IERC20(wston), msg.sender, wstonAmount);

        _distributeFees(0, fee);

        emit Swap(msg.sender, tonAmount, wstonAmount);
    }

    function updateStakingIndex(uint256 newIndex) external onlyOwner {
        require(newIndex >= stakingIndex, "cannot decrease the staking index");
        stakingIndex = newIndex;
        emit StakingIndexUpdated(newIndex);
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


    function getWstonReserve() external view returns(uint256) {
        return wstonReserve;
    }

    function getTonReserve() external view returns(uint256) {
        return tonReserve;
    }

    function getStakingIndex() external view returns (uint256) {
        // Assuming the staking index is the multiplier for WSTON value
        return stakingIndex;
    }

    function getLpShares(address lp) external view returns (uint256) {
        return lpShares[lp];
    }
}