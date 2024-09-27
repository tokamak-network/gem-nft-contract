// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract AirdropStorage {
    address public treasury;
    address public gemFactory;
    
    bool public paused;

    mapping(address => bool) public userClaimed;
    mapping(address => uint256[]) public tokensEligible;

    event TokensClaimed(uint256[] tokenIds, address to);
    event TokensAssigned(uint256[] tokenIds, address _to);

    error TokenNotOwnedByTreasury();
    error TokenNotAvailable();
    error UserAlreadyClaimedCurrentAirdrop();
    error UserNotEligible();
}