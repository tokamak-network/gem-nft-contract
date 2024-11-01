// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract AirdropStorage {
    address internal treasury;
    address internal gemFactory;
    address[] internal usersWithEligibleTokens;

    bool internal paused;
    bool internal initialized;

    mapping(address => bool) internal userClaimed;
    mapping(address => uint256[]) internal tokensEligible;
    mapping(address => bool) internal userHasEligibleTokens;

    event TokensClaimed(uint256[] tokenIds, address to);
    event TokensAssigned(uint256[] tokenIds, address _to);
    event EligibleTokenListCleared();

    error AlreadyInitialized();
    error TokenNotOwnedByTreasury();
    error TokenNotAvailable();
    error UserAlreadyClaimedCurrentAirdrop();
    error UserNotEligible();
    error NoEligibleUsers();
    error ContractNotPaused();
    error ContractPaused();
}