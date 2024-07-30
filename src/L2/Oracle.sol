// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Oracle is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    address public l1Contract;
    address public l2Contract;

    constructor(address _oracle, bytes32 _jobId, uint256 _fee, address _l1Contract, address _l2Contract) {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
        l1Contract = _l1Contract;
        l2Contract = _l2Contract;
    }

    function requestVariable() public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", string(abi.encodePacked("https://api.l1contract.com/variable/", l1Contract)));
        request.add("path", "variable");
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _variable) public recordChainlinkFulfillment(_requestId) {
        L2Contract(l2Contract).updateVariable(_variable);
    }
}
