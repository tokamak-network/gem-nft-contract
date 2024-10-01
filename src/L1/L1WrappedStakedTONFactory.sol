// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { L1WrappedStakedTON } from "./L1WrappedStakedTON.sol";

contract L1WrappedStakedTONFactory is OwnableUpgradeable {
    address public l1wton;
    address public l1ton;

    event WSTONTokenCreated(address indexed wston, address indexed layer2Address);

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Address cannot be zero");
        _;
    }

    function initialize(address _l1wton, address _l1ton) public initializer {
        __Ownable_init(msg.sender);
        l1wton = _l1wton;
        l1ton = _l1ton;
    }

    function createWSTONToken(
        address _layer2Address,
        address _depositManager,
        address _seigManager,
        string memory _name,
        string memory _symbol
    ) external onlyOwner 
    nonZeroAddress(_layer2Address) 
    nonZeroAddress(_depositManager) 
    nonZeroAddress(_seigManager) 
    returns(address)  {

        L1WrappedStakedTON wstonImplementation = new L1WrappedStakedTON();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(wstonImplementation),
            abi.encodeWithSelector(
                L1WrappedStakedTON.initialize.selector,
                _layer2Address,
                l1wton,
                l1ton,
                _depositManager,
                _seigManager,
                _name,
                _symbol
            )
        );

        emit WSTONTokenCreated(address(proxy), _layer2Address);

        return address(proxy);
    }
}
