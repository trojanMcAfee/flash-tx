//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;


import './interfaces/MyIERC20.sol';
import './libraries/Helpers.sol';
import './FlashLoaner.sol';

import "hardhat/console.sol";




contract RevengeOfTheFlash {



    // function executeCont(address _weth, ZrxQuote calldata _TUSDWETH_0x_quote) public {
    //     uint amount;
    //     address[] memory _path;
    //     // MyIERC20 IWETH = MyIERC20(_weth);

    // //SUSHISWAP 
    //     MyIERC20(TUSD).approve(sushiRouter, type(uint).max);
    //     amount = 11173 * 1 ether;
    //     _path = Helpers._createPath(TUSD, _weth);
    //     // address[] memory _path = new address[](2);
    //     // _path[0] = TUSD;
    //     // _path[1] = _weth;
    //     uint[] memory _amount;
    //     _amount = IUniswapV2Router02(sushiRouter).swapExactTokensForETH(amount, 0, _path, payable(address(this)), block.timestamp);
    //     console.log('8.- ETH traded (Sushiswap swap): ', _amount[1] / 1 ether, '--', _amount[1]);

    //     //0x
    //     //(TUSD to WETH)
    //     console.log('9. - WETH balance before TUSD swap: ', MyIERC20(_weth).balanceOf(address(this)));


    //     (bool success, bytes memory data) = swaper0x.call{gas: 1000000}(
    //         abi.encodeWithSignature('fillQuote(address,address,address,address,bytes)',
    //             _TUSDWETH_0x_quote.sellTokenAddress,
    //             _TUSDWETH_0x_quote.buyTokenAddress,
    //             _TUSDWETH_0x_quote.spender,
    //             _TUSDWETH_0x_quote.swapTarget,
    //             _TUSDWETH_0x_quote.swapCallData  
    //         )
    //     );
    //     console.log('success: ', success);


        // console.log('gas left: ', gasleft());
        // fillQuote(
            // _TUSDWETH_0x_quote.sellTokenAddress,
            // _TUSDWETH_0x_quote.buyTokenAddress,
            // _TUSDWETH_0x_quote.spender,
            // _TUSDWETH_0x_quote.swapTarget,
            // _TUSDWETH_0x_quote.swapCallData
        // );
        // console.log('9. - WETH balance after TUSD swap without 1 ether: ', IWETH.balanceOf(address(this)));
        // console.log('9. - WETH balance after TUSD swap: ', IWETH.balanceOf(address(this)) / 1 ether);

        
        //UNISWAP
        // MyIERC20(USDC).approve(uniswapRouter, type(uint).max);
        // amount = 44739 * 10 ** 6;
        // _path = _createPath(USDC, WBTC);
        // _amount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amount, 0, _path, address(this), block.timestamp);
        // console.log('10.- WBTC balance after Uniswap swap: ', MyIERC20(WBTC).balanceOf(address(this)) / 10 ** 8, '--', _amount[1]);

        // //0x
        // //(USDC to WBTC)
        // fillQuote(
        //     _USDCWBTC_0x_quote.sellTokenAddress,
        //     _USDCWBTC_0x_quote.buyTokenAddress,
        //     _USDCWBTC_0x_quote.spender,
        //     _USDCWBTC_0x_quote.swapTarget,
        //     _USDCWBTC_0x_quote.swapCallData
        // );   
        // console.log('11.- WBTC balance after 0x swap: ', MyIERC20(WBTC).balanceOf(address(this)) / 10 ** 8);

    // }
}