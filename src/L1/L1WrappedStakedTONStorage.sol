// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract L1WrappedStakedTONStorage {
    struct WithdrawalRequest {
        uint256 withdrawableBlockNumber;
        uint256 amount;
        bool processed;
    }

    uint256 public constant DECIMALS = 10**27;

    bool paused;

    address public layer2Address;
    address public wton;
    address public ton;
    address internal depositManager;
    address internal seigManager;

    uint256 public totalStakedAmount;
    uint256 public totalWstonMinted;
    uint256 internal stakingIndex;
    uint256 public lastSeigBlock;

    mapping(address => WithdrawalRequest[]) public withdrawalRequests;
    mapping (address => uint256) internal withdrawalRequestIndex;

    // Array to keep track of users who have made withdrawal requests
    address[] internal users;
    mapping(address => bool) internal userExists;

    //deposit even
    event Deposited(address to, bool token, uint256 amount, uint256 wstonAmount, uint256 depositTime, uint256 depositBlockNumber);
    event SeigniorageUpdated();

    // withdrawal events
    event WithdrawalRequested(address indexed _to, uint256 amount);
    event DebugAllowance(address indexed owner, address indexed spender, uint256 value);
    event DebugBalance(address indexed account, uint256 balance);
    event WithdrawalProcessed(address _to, uint256 amount);

    //staking index update
    event StakingIndexUpdated(uint256 stakingIndex);

    // Pause Events
    event Paused(address account);
    event Unpaused(address account);

    // errors
    error DepositFailed();
    error NotEnoughFunds();
    error WrontAmount();
    error NoRequestToProcess();
    error RequestAlreadyProcessed();
    error WithdrawalDelayNotElapsed();
    error NoClaimableAmount(address requestor);
    error FailedToSwapFromTONToWTON(uint256 amount);
      

}