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

  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  //show in the beginning the healfactor and userdata of the caller
  // exchange some ETH to USDC and transfer it to flashlogic so it can deposit it

}