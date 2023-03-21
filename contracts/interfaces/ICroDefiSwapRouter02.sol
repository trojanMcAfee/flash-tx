// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface ICroDefiSwapRouter02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}