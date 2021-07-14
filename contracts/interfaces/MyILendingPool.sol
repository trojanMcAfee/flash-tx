// // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface MyILendingPool {

    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function paused() external view returns (bool);
  function getReservesList() external view returns (address[] memory);

}