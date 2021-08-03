//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/ICurve.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/I1inchProtocol.sol';
import './interfaces/IBalancerV1.sol';
import {IKyberRouter, IKyberFactory, IPoolWETHUSDT} from './interfaces/IKyber.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './libraries/Helpers.sol';

import 'hardhat/console.sol';



contract Swaper0x {

    MyIERC20 USDT;
    MyIERC20 WBTC;
    MyIERC20 WETH;
    MyIERC20 USDC;
    MyIERC20 BNT;
    MyIERC20 TUSD;
    MyIERC20 ETH_Bancor;
    MyILendingPool lendingPoolAAVE;
    IContractRegistry ContractRegistry_Bancor;
    ICurve yPool;
    IUniswapV2Router02 sushiRouter;
    IUniswapV2Router02 uniswapRouter;
    I1inchProtocol oneInch;
    IBancorNetwork bancorNetwork;
    IKyberRouter kyberRouter;
    IKyberFactory kyberFactory;
    IBalancerV1 balancerWBTCETHpool_1;
    

    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }


    address swaper0x;
    address revengeOfTheFlash;

    receive() external payable {}


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


    function useCurve() external {
        //TUSD to USDT
        MyIERC20(TUSD).approve(address(yPool), type(uint).max);
        uint amount = 882693 * 1 ether;
        yPool.exchange_underlying(3, 2, amount, 1);

        console.log('USDT balance: ', USDT.balanceOf(address(this)) / 10 ** 6);

        //USDT to WETH

        address[] memory pools = kyberFactory.getPools(USDT, WETH);
        MyIERC20[] memory path = new MyIERC20[](2);
        path[0] = USDT;
        path[1] = WETH;
        amount = USDT.balanceOf(address(this));
        // console.log('amount to swap on kyber: ', amount / 10 ** 6);


        console.log('pool: ', pools[0]);
        console.log('msg.sender: ', msg.sender);
        console.log('address(this): ', address(this));

        address poolAddr = pools[0];
        IPoolWETHUSDT pool = IPoolWETHUSDT(poolAddr);
        address token0 = pool.token0();
        console.log('token0: ', token0);

        // (uint112 reserve0, uint112 reserve1, uint32 timestamp) = pool.getReserves();
        // console.log('reserve0: ', reserve0);
        // console.log('reserve1: ', reserve1);
        // console.log('timestamp: ', timestamp);

        // (uint112 reserve02, uint112 reserve12, uint112 vReserve0, uint112 vReserve1, ) = pool.getTradeInfo();
        // console.log('reserve02: ', reserve02 / 10 ** 18);
        // console.log('reserve12: ', reserve12 / 10 ** 6);
        // console.log('vReserve0: ', vReserve0 / 10 ** 18);
        // console.log('vReserve1: ', vReserve1 / 10 ** 6);


        USDT.approve(address(kyberRouter), type(uint).max);
        console.log('hi3');
        // kyberRouter.swapExactTokensForTokens(amount, 0, poolPath, path, address(this), block.timestamp);
        // kyberRouter.swapExactTokensForETH(amount, 0, pools, path, address(this), block.timestamp);
       

        console.log('WETH balance: ', WETH.balanceOf(address(this)));
    }






}