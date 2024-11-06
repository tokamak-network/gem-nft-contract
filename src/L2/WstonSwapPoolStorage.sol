// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;


contract WstonSwapPoolStorage {
   // Constants
   uint256 public constant DECIMALS = 10**27;
    
    // Addresses
    address public ton;
    address public wston;
    address public treasury;

    // Uint256
    uint256 internal stakingIndex;
    
    // Bools
    bool internal initialized;
    bool internal paused;

    // Events
    event SwappedWstonForTon(address indexed user, uint256 tonAmount, uint256 wstonAmount);
    event StakingIndexUpdated(uint256 newIndex);

    // Errors
    error WstonAllowanceTooLow();
    error WstonBalanceTooLow();
    error ContractTonBalanceOrAllowanceTooLow();
    error WrongStakingIndex();
    error FailedToApproveTon(uint256 amount);
    error FailedToTransferTON();

}