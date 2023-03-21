//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import {IContractRegistry, IBancorNetwork} from '../interfaces/IBancor.sol';
import '../interfaces/IAaveProtocolDataProvider.sol';
import '../interfaces/ICroDefiSwapRouter02.sol';
import '../interfaces/MyILendingPool.sol';
import '../interfaces/IBalancerV1.sol';
import '../interfaces/IDODOProxyV2.sol';
import '../interfaces/ICurve.sol';
import '../interfaces/MyIERC20.sol';
import '../libraries/MySafeERC20.sol';
import './Helpers.sol';



contract Exchange is Ownable, Helpers {

    MyIERC20 USDT;
    MyIERC20 WBTC;
    MyIERC20 WETH;
    MyIERC20 USDC;
    MyIERC20 BNT;
    MyIERC20 TUSD;
    MyIERC20 ETH;
    IWETH WETH_int;
    MyILendingPool lendingPoolAAVE;
    IContractRegistry ContractRegistry_Bancor;
    ICurve yPool;
    ICurve dai_usdc_usdt_Pool;
    IUniswapV2Router02 sushiRouter;
    IUniswapV2Router02 uniswapRouter;
    IBancorNetwork bancorNetwork;
    IBalancerV1 balancerWBTCETHpool_1;
    IBalancerV1 balancerWBTCETHpool_2;
    IBalancerV1 balancerETHUSDCpool;
    IDODOProxyV2 dodoProxyV2;
    ICroDefiSwapRouter02 croDefiRouter;
    IAaveProtocolDataProvider aaveProtocolDataProvider;
    Exchange exchange;


    event UserHealthFactor(uint hf);

    address myExchange;
    address revengeOfTheFlash;

    receive() external payable {}


    function getUserHealthFactor_aave(address _user) external {
        lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        (, , , , , uint healthFactor) = lendingPoolAAVE.getUserAccountData(_user);
        emit UserHealthFactor(healthFactor);
    }


    function withdrawFromPool(MyIERC20 _tokenOut, address _recipient, uint _amountTokenOut) external returns(uint) {
        _tokenOut.transfer(_recipient, _amountTokenOut);
        return _amountTokenOut;
    }


    function bancorSwap(MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) external returns(uint) {
        MyIERC20[] memory path = bancorNetwork.conversionPath(_tokenIn, _tokenOut);
        uint minReturn = bancorNetwork.rateByPath(path, _amount);
        _tokenIn.approve(address(bancorNetwork), _amount);
        uint amountTraded = bancorNetwork.convertByPath(path, _amount, minReturn, address(this), address(0x0), 0);
        return amountTraded;
    }


    function dodoSwapV1(address _pool, MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) external returns(uint) {
        address[] memory dodoPairs = new address[](1);
        dodoPairs[0] = _pool;
        address DODOapprove = 0xCB859eA579b28e02B87A1FDE08d087ab9dbE5149;
        _tokenIn.approve(DODOapprove, type(uint).max);
        uint tradedAmount = dodoProxyV2.dodoSwapV1(
            address(_tokenIn),
            address(_tokenOut),
            _amount,
            1,
            dodoPairs,
            1,
            false,
            block.timestamp
        );
        return tradedAmount;
    }


    function sushiUniCro_swap(
        ICroDefiSwapRouter02 _router, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut
    ) external returns(uint) {
        MySafeERC20.safeApprove(_tokenIn, address(_router), _amount);
        address[] memory path = _createPath(address(_tokenIn), address(_tokenOut));
        uint[] memory tradedAmounts =_router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return tradedAmounts[1];
    }


    function sushiUniCro_swap(
        IUniswapV2Router02 _router, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut, 
        uint _dir
    ) external returns(uint) {
        MySafeERC20.safeApprove(_tokenIn, address(_router), _amount);
        address[] memory _path = _createPath(address(_tokenIn), address(_tokenOut));
        uint[] memory tradedAmounts = 
            _dir == 1 
                ? 
            _router.swapExactTokensForETH(_amount, 0, _path, address(this), block.timestamp)
                :
            _router.swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);
        return tradedAmounts[1];
    }


    function balancerSwapV1(
        IBalancerV1 _pool, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut
    ) external returns(uint) {
        _tokenIn.approve(address(_pool), _amount);
        (uint tradedAmount, ) = _pool.swapExactAmountIn(
            address(_tokenIn), 
            _amount, 
            address(_tokenOut), 
            0, 
            type(uint).max
        );
        WETH_int.withdraw(tradedAmount);
        return tradedAmount;
    }


    function curveSwap(
        ICurve _pool,
        MyIERC20 _tokenIn, 
        uint _amountTokenIn, 
        int128 _numTokenIn, 
        int128 _numTokenOut,
        uint _dir
    ) external {
        _tokenIn.approve(address(_pool), _amountTokenIn);
        _dir == 1
            ?
        _pool.exchange_underlying(_numTokenIn, _numTokenOut, _amountTokenIn, 1)
            :
        _pool.exchange(_numTokenIn, _numTokenOut, _amountTokenIn, 1);
    }
}