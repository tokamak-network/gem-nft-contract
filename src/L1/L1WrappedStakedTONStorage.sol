// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract L1WrappedStakedTONStorage {
    struct WithdrawalRequest {
        uint256 withdrawableBlockNumber;
        uint256 amount;
        bool processed;
    }

    bool paused;

    address public layer2Address;
    address public wton;
    address public depositManager;
    address public seigManager;

    uint256 public totalStakedAmount;
    uint256 public stakingIndex;

    mapping(address => WithdrawalRequest[]) public withdrawalRequests;
    mapping (address => uint256) internal withdrawalRequestIndex;

    //deposit even
    event Deposited(address to, uint256 amount, uint256 wstonAmount, uint256 depositTime, uint256 depositBlockNumber);

    // Process withdrawal event
    event WithdrawalProcessed(address _to, uint256 amount);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);
}