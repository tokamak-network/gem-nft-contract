// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {AuthControl} from "../common/AuthControl.sol";
import { L1WrappedStakedTON } from "./L1WrappedStakedTON.sol";
import { L1WrappedStakedTONFactoryStorage } from "./L1WrappedStakedTONFactoryStorage.sol";
import { L1WrappedStakedTONProxy } from "./L1WrappedStakedTONProxy.sol";
import "../proxy/ProxyStorage.sol";

contract L1WrappedStakedTONFactory is ProxyStorage, AuthControl, L1WrappedStakedTONFactoryStorage {

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Address cannot be zero");
        _;
    }

    /**
     * @notice Initializes the factory contract with the given WTON and TON addresses.
     * @param _l1wton The address of the L1 WTON token.
     * @param _l1ton The address of the L1 TON token.
     */
    function initialize(address _l1wton, address _l1ton) external {
        if(initialized) {
            revert AlreadyInitialized();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        l1wton = _l1wton;
        l1ton = _l1ton;
        initialized = true;
    }

    /**
     * @notice Creates a new WSTON token proxy and initializes it. Only the factory owner or admins ar authorized to call this function.
     * @notice the function caller becomes the contract owner and is able to upgrade it through the upgradeWstonTo function
     * @param _layer2Address The address of the Layer 2 contract.
     * @param _depositManager The address of the DepositManager contract.
     * @param _seigManager The address of the SeigManager contract.
     * @param _name The name of the ERC20 token.
     * @param _symbol The symbol of the ERC20 token.
     * @return The address of the newly created WSTON token proxy.
     */
    function createWSTONToken(
        address _layer2Address,
        address _depositManager,
        address _seigManager,
        uint256 _minimumWithdrawalAmount,
        uint8 _maxNumWithdrawal,
        string memory _name,
        string memory _symbol
    ) external onlyOwnerOrAdmin 
    nonZeroAddress(_layer2Address) 
    nonZeroAddress(_depositManager) 
    nonZeroAddress(_seigManager) 
    returns(address)  {

        // instanciate the proxy with owner = msg.sender
        L1WrappedStakedTONProxy proxy = new L1WrappedStakedTONProxy();
        // upgrade to the current implementation
        proxy.upgradeTo(wstonImplementation);
        address proxyAddress = address(proxy);
        L1WrappedStakedTON(proxyAddress).initialize(
            _layer2Address,
            l1wton,
            l1ton,
            _depositManager,
            _seigManager,
            msg.sender,
            _minimumWithdrawalAmount,
            _maxNumWithdrawal,
            _name,
            _symbol
        );


        emit WSTONTokenCreated(proxyAddress, _layer2Address);

        return proxyAddress;
    }

    /**
     * @notice Sets the implementation address for WSTON tokens.
     * @param _imp The address of the new implementation contract.
     */
    function setWstonImplementation(address _imp) external onlyOwner { 
       wstonImplementation = _imp;  
    }


    /**
     * @notice Upgrades the WSTON token proxy to a new implementation.
     * @param wstonProxyAddress The address of the WSTON token proxy to upgrade.
     * @param newImplementation The address of the new implementation contract.
     */
    function upgradeWstonTo(address wstonProxyAddress, address newImplementation) external {
        if(msg.sender != L1WrappedStakedTON(wstonProxyAddress).owner()) {
            revert NotContractOwner();
        }
        L1WrappedStakedTONProxy(payable(wstonProxyAddress)).upgradeTo(newImplementation);
        emit L1WrappedStakedTONContractUgraded(newImplementation);
    }
}
