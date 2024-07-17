// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ProxyStorage.sol";
import {AuthControlGemFactory} from "../common/AuthControlGemFactory.sol";

contract ProxySeigManager is
    ProxyStorage,
    AuthControlGemFactory,
    IProxyEvent,
    IProxyAction
{}
