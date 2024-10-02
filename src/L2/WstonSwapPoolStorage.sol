// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;


contract WstonSwapPoolStorage {
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

    bool internal initialized;

    event SwappedWstonForTon(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event SwappedTonForWston(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event StakingIndexUpdated(uint256 newIndex);
    event LiquidityAdded(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event LiquidityRemoved(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event FeesCollected(uint256 tonFees, uint256 wstonFees);

    error TonAllowanceTooLow();
    error WstonAllowanceTooLow();
    error TonBalanceTooLow();
    error WstonBalanceTooLow();
    error InsufficientLpShares();
    error ContractTonBalanceTooLow();
    error ContractWstonBalanceTooLow();
    error WrongStakingIndex();

}