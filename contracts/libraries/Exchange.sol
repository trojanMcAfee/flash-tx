// //SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.0;


// import '../interfaces/MyIERC20.sol';


// contract Exchange {

//     constructor(address _flashloaner) {
//         flashloaner = _flashloaner;
//     }

//     address offchainRelayer = 0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9;
//     address flashloaner;

//     function swap0x(address _tokenOut, address _recipient, uint _amountOut) external {
//         MyIERC20(_tokenOut).transfer(_recipient, _amountOut);
//     }

// }