//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';
import './libraries/Helpers.sol';

import "hardhat/console.sol";


contract FlashLoaner {

    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address public logicContract;
    uint public borrowed;


    function execute(address _weth, uint256 _borrowed, ZrxQuote calldata _zrxQuote) public {
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 weth = MyIERC20(_weth);
        address USDC = _zrxQuote.sellTokenAddress;
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        address flashloaner = address(this);

        weth.approve(address(lendingPoolAAVE), _borrowed); 
        lendingPoolAAVE.deposit(_weth, _borrowed, flashloaner, 0); 
       lendingPoolAAVE.borrow(USDC, aaveUSDCloan, 2, 0, flashloaner); 
        
        uint usdcBalance = MyIERC20(USDC).balanceOf(flashloaner); 
        console.log('USDC balance: ', usdcBalance / 10 ** 6); 

        fillQuote(
            _zrxQuote.sellTokenAddress,
            _zrxQuote.buyTokenAddress,
            _zrxQuote.spender,
            _zrxQuote.swapTarget,
            _zrxQuote.swapCallData
        );   
    }

    function fillQuote(
        address sellToken,
        address buyToken,
        address spender,
        address swapTarget,
        bytes calldata swapCallData
    ) private   
    {        
        require(MyIERC20(sellToken).approve(spender, type(uint).max));
   
        (bool success, bytes memory returnData) = swapTarget.call(swapCallData);
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        require(success, 'SWAP_CALL_FAILED');
        console.log('BNT balance after swap: ', MyIERC20(buyToken).balanceOf(address(this)) / 10 ** 12);
    }
}



