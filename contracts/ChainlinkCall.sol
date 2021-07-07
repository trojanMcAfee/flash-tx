//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


import '@chainlink/contracts/src/v0.6/ChainlinkClient.sol';


contract ChainlinkCall is ChainlinkClient {
    
    address public preCoordinator;
    bytes32 public serviceAgreementID;
    uint public ORACLE_PAYMENT = 5 * LINK;
    uint public currentPrice;

    constructor(address _preCoordinatorAddr, bytes32 _saId) public {
        setPublicChainlinkToken();
        preCoordinator = _preCoordinatorAddr;
        serviceAgreementID = _saId;
    }


    function requestPrice(address _oracle, bytes32 _jobId, string memory _apiRequest) public {
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        // req.add('get', _apiRequest);

        req.add('get', "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        req.add("path", "USD");
        req.addInt("times", 100);

        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);

    }

    function fulfill(bytes32 _requestId, uint _price) public recordChainlinkFulfillment(_requestId) {
        currentPrice = _price;
    }

    function getData(string memory _apiRequest) public returns (uint) {
        // string memory x = 'Hello world';
        // return x;
        requestPrice(preCoordinator, serviceAgreementID, _apiRequest);
        uint price = getPrice();
        return price;
    }

    function getPrice() internal view returns (uint) {
        return currentPrice;
    }



}