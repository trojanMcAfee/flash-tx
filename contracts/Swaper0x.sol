//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/MyIERC20.sol';
import './libraries/Helpers.sol';

import 'hardhat/console.sol';



contract Swaper0x {


    function fillQuote(
        address sellToken,
        address buyToken,
        address spender,
        address swapTarget,
        bytes calldata swapCallData
    ) external   
    {        
        require(MyIERC20(sellToken).approve(spender, type(uint).max));
        (bool success, bytes memory returnData) = swapTarget.call(swapCallData);
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        require(success, 'SWAP_CALL_FAILED');
    }


    function getHello(uint256 num) external view {
        console.log(num);
    }
   



}