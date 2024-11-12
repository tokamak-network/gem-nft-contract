// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TreasuryStorage {
    address internal gemFactory;
    address internal _marketplace;
    address internal randomPack;
    address internal airdrop;
    address internal wston;
    address internal ton;
    address internal wstonSwapPool;

    uint256 constant public DECIMALS = 10**27;
    uint256 constant public TON_FEES_RATE_DIVIDER = 10000;

    bool paused = false;
    bool internal initialized;

    error InvalidAddress();
    error WstonAddressIsNotSet();
    error TonAddressIsNotSet();
    error UnsuffiscientWstonBalance();
    error UnsuffiscientTonBalance();
    error NotEnoughWstonAvailableInTreasury();
    error FailedToSendTON();
    error NotEnoughTonAvailableInTreasury();
}