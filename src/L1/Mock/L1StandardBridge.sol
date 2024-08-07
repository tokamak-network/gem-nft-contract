// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IL1StandardBridge } from "../../interfaces/IL1StandardBridge.sol";


contract L1StandardBridge is IL1StandardBridge {

    address public wton;

    event Bridged(address l2Token, address to, uint256 amount);

    function depositERC20To(
        address /*_l1Token*/,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 /*_l2Gas*/,
        bytes calldata /*_data*/
    ) external {
        emit Bridged(_l2Token, _to, _amount);
    }
}