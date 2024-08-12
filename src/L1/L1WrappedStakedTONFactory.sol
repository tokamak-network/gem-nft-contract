// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { L1WrappedStakedTON } from "./L1WrappedStakedTON.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract L1WrappedStakedTONFactory is Ownable {

    address public l1wton;

    event WSTONTokenCreated(address token, address layer2Address);

    constructor(address _l1wton) Ownable(msg.sender) {
        l1wton = _l1wton;
    }
    
    function createWSTONToken(
        address _layer2Address,
        address _depositManager,
        address _seigManager,
        string memory _name,
        string memory _symbol
    ) external onlyOwner returns(address) {
        require(_layer2Address != address(0), "Must provide a layer2 candidate");
        require(_depositManager != address(0), "Must provide the deposit manager address");
        require(_seigManager != address(0), "Must provide the seig manager address");

        L1WrappedStakedTON wston = new L1WrappedStakedTON(
            _layer2Address,
            l1wton,
            _depositManager,
            _seigManager,
            _name,
            _symbol
        );

        emit WSTONTokenCreated(address(wston),_layer2Address);

        return address(wston);
    }
}