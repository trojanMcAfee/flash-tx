//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;


interface IPreCoordinator {
    function createServiceAgreement(
    uint256 _minResponses,
    address[] calldata _oracles,
    bytes32[] calldata _jobIds,
    uint256[] calldata _payments
  )
    external returns (bytes32 saId);
}