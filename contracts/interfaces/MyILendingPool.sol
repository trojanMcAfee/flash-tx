// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

// interface MyILendingPool {
//     function deposit(
//     address asset,
//     uint256 amount,
//     address onBehalfOf,
//     uint16 referralCode
//   ) external;
// }

import '@aave/protocol-v2/contracts/interfaces/ILendingPool.sol';

import 'hardhat/console.sol';

contract MyILendingPool {
    ILendingPool liquidityPoolAAVE = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    
    function supplyToAAVE() external {
        // uint x = liquidityPoolAAVE.paused();
        // console.log(x);
    }
}