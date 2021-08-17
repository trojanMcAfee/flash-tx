//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface IETHgateway {

function depositETH(
    address lendingPool,
    address onBehalfOf,
    uint16 referralCode
  ) external payable;


  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address to
  ) external;


}