//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import '../libraries/DataTypesAAVE.sol';



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

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);


  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);



}