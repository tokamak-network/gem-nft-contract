// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { L1WrappedStakedTON } from "./L1WrappedStakedTON.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract L1WrappedStakedTONFactory is Ownable {

    address public l1wton;
    address public l1ton;

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "zeroAddress");
        _;
    }

    event WSTONTokenCreated(address token, address layer2Address);

    constructor(address _l1wton, address _l1ton) Ownable(msg.sender) {
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

        L1WrappedStakedTON wston = new L1WrappedStakedTON(
            _layer2Address,
            l1wton,
            l1ton,
            _depositManager,
            _seigManager,
            _name,
            _symbol
        );

        emit WSTONTokenCreated(address(wston),_layer2Address);

        return address(wston);
    }
}