//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './MyIERC20.sol';


interface I1inchProtocol {
    function getExpectedReturn(
        address fromToken,
        MyIERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags 
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        MyIERC20 fromToken,
        MyIERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, 
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        address fromToken,
        MyIERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);

        function swapMulti(
        MyIERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    )
        external
        payable
        returns(uint256 returnAmount);

}