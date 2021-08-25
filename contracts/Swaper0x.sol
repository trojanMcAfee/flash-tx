//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/ICurve.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/I1inchProtocol.sol';
import './interfaces/IBalancerV1.sol';
import './interfaces/IExchange0xV2.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import './interfaces/IDODOProxyV2.sol';
import './interfaces/ICroDefiSwapRouter02.sol';
import './libraries/MySafeERC20.sol';

import './libraries/DataTypesAAVE.sol';
import './interfaces/IAaveProtocolDataProvider.sol';
import './interfaces/IDebtTokenAAVE/IStableDebtToken.sol';


import './libraries/Helpers.sol';

import 'hardhat/console.sol';



contract Swaper0x {

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
    I1inchProtocol oneInch;
    IBancorNetwork bancorNetwork;
    IBalancerV1 balancerWBTCETHpool_1;
    IBalancerV1 balancerWBTCETHpool_2;
    IBalancerV1 balancerETHUSDCpool;
    IDODOProxyV2 dodoProxyV2;
    IExchange0xV2 exchange0xV2;
    ICroDefiSwapRouter02 croDefiRouter;
    Swaper0x exchange;
    MyIERC20 aWETH;
    MyIERC20 aUSDC;

    IAaveProtocolDataProvider aaveProtocolDataProvider;


    struct FillResults {
        uint256 makerAssetFilledAmount;  
        uint256 takerAssetFilledAmount;  
        uint256 makerFeePaid;            
        uint256 takerFeePaid;            
    }

    struct Order {
        address makerAddress;               
        address takerAddress;              
        address feeRecipientAddress;    
        address senderAddress;         
        uint256 makerAssetAmount;        
        uint256 takerAssetAmount;           
        uint256 makerFee;             
        uint256 takerFee;              
        uint256 expirationTimeSeconds;           
        uint256 salt;                   
        bytes makerAssetData;          
        bytes takerAssetData;       
    }
    

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

    event UserHealthFactor(uint hf);



    // function delegateCredit(address _borrower) external {
    //     address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //     IAaveProtocolDataProvider aaveProtocolDataProvider = IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    //     (, address stableDebtToken, ) = aaveProtocolDataProvider.getReserveTokensAddresses(USDC);

    //     IStableDebtToken(stableDebtToken).approveDelegation(_borrower, type(uint).max);
    // }

    // function getUserData_aave(address _asset, address _user) external returns(uint) {
    //     IAaveProtocolDataProvider aaveProtocolDataProvider = IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    //     (uint a, uint b, uint variableDebt, uint d, uint e, uint f, uint g, uint40 h, bool i) = aaveProtocolDataProvider.getUserReserveData(_asset, _user);
    //     return variableDebt;
    // } 

    function getUserData_aave(address _user) external view {
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        (uint a, uint b, uint c, uint d, uint e, uint f) = lendingPoolAAVE.getUserAccountData(_user);

        console.log('totalCollateralETH: ', a / 1 ether);
        console.log('totalDebtETH: ', b / 1 ether);
        console.log('availableBorrowsETH: ', c / 1 ether);
        console.log('currentLiquidationThreshold: ', d);
        console.log('ltv: ', e);
        console.log('healthFactor: ', f / 1 ether);

        
    }

    


    function getUserHealthFactor_aave(address _user) external {
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        (, , , , , uint healthFactor) = lendingPoolAAVE.getUserAccountData(_user);
        emit UserHealthFactor(healthFactor);
    }



    function withdrawFromPool(MyIERC20 _tokenOut, address _recipient, uint _amountTokenOut) external returns(uint) {
        _tokenOut.transfer(_recipient, _amountTokenOut);
        return _amountTokenOut;
    }


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
    
    


    function bancorSwap(MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) external returns(uint) {
        MyIERC20[] memory path = bancorNetwork.conversionPath(_tokenIn, _tokenOut);
        uint minReturn = bancorNetwork.rateByPath(path, _amount);
        _tokenIn.approve(address(bancorNetwork), _amount);
        uint amountTraded = bancorNetwork.convertByPath(path, _amount, minReturn, address(this), address(0x0), 0);
        return amountTraded;
    }



    function dodoSwapV1(address _pool, MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) private returns(uint) {
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



    // function oneInchSwap(MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) private returns(uint) {
    //     _tokenIn.approve(address(oneInch), type(uint).max);

    //     (uint expectedReturn, uint[] memory _distribution) = oneInch.getExpectedReturn(
    //         _tokenIn,
    //         _tokenOut,
    //         _amount,
    //         10,
    //         0
    //     );
    //     oneInch.swap(_tokenIn, _tokenOut, _amount, 0, _distribution, 0);

    //     return expectedReturn;
    // }




    function sushiUniCro_swap(
        ICroDefiSwapRouter02 _router, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut
    ) external returns(uint) {
        MySafeERC20.safeApprove(_tokenIn, address(_router), _amount);
        address[] memory path = Helpers._createPath(address(_tokenIn), address(_tokenOut));

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
        address[] memory _path = Helpers._createPath(address(_tokenIn), address(_tokenOut));
        uint[] memory tradedAmounts = 
            _dir == 1 
                ? 
            _router.swapExactTokensForETH(_amount, 0, _path, address(this), block.timestamp)
                :
            _router.swapExactTokensForTokens(_amount, 0, _path, address(this), block.timestamp);

        return tradedAmounts[1];
    }



    function balancerSwapV1(IBalancerV1 _pool, uint _amount) private returns(uint) {
        WBTC.approve(address(_pool), type(uint).max);

        (uint tradedAmount, ) = _pool.swapExactAmountIn(
            address(WBTC), 
            _amount, 
            address(WETH), 
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