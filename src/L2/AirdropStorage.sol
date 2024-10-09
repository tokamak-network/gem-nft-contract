// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract AirdropStorage {
    address public treasury;
    address public gemFactory;
    address[] internal usersWithEligibleTokens;

    bool public paused;
    bool internal initialized;

    mapping(address => bool) public userClaimed;
    mapping(address => uint256[]) public tokensEligible;
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
}