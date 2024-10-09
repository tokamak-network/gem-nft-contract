// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract L1WrappedStakedTONFactoryStorage {
    address public l1wton;
    address public l1ton;
    address public wstonImplementation; 

    bool initialized;


    event WSTONTokenCreated(address indexed wston, address indexed layer2Address);
    event L1WrappedStakedTONContractUgraded(address newImplementation);

    error NotContractOwner();
    error AlreadyInitialized();
}