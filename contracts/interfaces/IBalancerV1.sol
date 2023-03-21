//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IBalancerV1 {
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external  returns (uint tokenAmountOut, uint spotPriceAfter);

    function getNumTokens() external returns (uint);
    function getCurrentTokens() external view returns (address[] memory tokens);
}