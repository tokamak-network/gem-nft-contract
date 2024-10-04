// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TreasuryStorage {
    address public gemFactory;
    address public _marketplace;
    address public randomPack;
    address public airdrop;
    address public wston;
    address public ton;
    address public wstonSwapPool;

    bool paused = false;
    bool public initialized;

    error InvalidAddress();
    error WstonAddressIsNotSet();
    error TonAddressIsNotSet();
    error UnsuffiscientWstonBalance();
    error UnsuffiscientTonBalance();
    error NotEnoughWstonAvailableInTreasury();
}