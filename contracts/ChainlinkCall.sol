//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


import '@chainlink/contracts/src/v0.6/ChainlinkClient.sol';

contract ChainlinkCall is ChainlinkClient {
    
    address private preCoordinatorAddr;
    bytes32 private serviceAgreementID;
    uint public ORACLE_PAYMENT = 5 * LINK;

    constructor(address _preCoordinatorAddr, bytes32 _saId) public {
        setPublicChainlinkToken();
        preCoordinatorAddr = _preCoordinatorAddr;
        serviceAgreementID = _saId;
    }


    // function requestPrice(address _oracle, bytes32 _jobId) external {
    //     Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        // req.add('get', );
    // }



}