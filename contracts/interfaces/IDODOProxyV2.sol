//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IDODOProxyV2 {

    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    )
        external
        payable
        returns (uint256 returnAmount);

}