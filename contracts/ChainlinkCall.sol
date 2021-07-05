//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


import '@chainlink/contracts/src/v0.6/ChainlinkClient.sol';
import 'hardhat/console.sol';

contract ChainlinkCall is ChainlinkClient {
    
    address private preCoordinator;
    bytes32 private serviceAgreementID;
    uint public ORACLE_PAYMENT = 5 * LINK;
    bytes32 public currentPrice;

    constructor(address _preCoordinatorAddr, bytes32 _saId) public {
        setPublicChainlinkToken();
        preCoordinator = _preCoordinatorAddr;
        serviceAgreementID = _saId;
    }


    function requestPrice(address _oracle, bytes32 _jobId, string memory _apiRequest) internal {
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        req.add('get', _apiRequest);


        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);

    }

    function fulfill(bytes32 _requestId, bytes32 _price) internal recordChainlinkFulfillment(_requestId) {
        currentPrice = _price;
        console.log('This is: ', currentPrice);
    }

    function getData(string memory _apiRequest) internal {
        requestPrice(preCoordinator, serviceAgreementID, _apiRequest);
    }

    function getPrice() internal returns (bytes32 memory) {
        return currentPrice;
    }



}