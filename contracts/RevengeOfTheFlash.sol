//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;


import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IExchange0xV2.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/ICurve.sol';
import './libraries/Helpers.sol';
import './libraries/Structs0x.sol';
import './FlashLoaner.sol';
import './interfaces/I1inchProtocol.sol';
import './Swaper0x.sol';
import './libraries/MySafeERC20.sol';
import './interfaces/ICroDefiSwapRouter02.sol';

import './libraries/DataTypesAAVE.sol';
import './interfaces/IDebtTokenAAVE/IVariableDebtToken.sol';
import './interfaces/IAaveProtocolDataProvider.sol';
import './interfaces/IAToken.sol';
import './interfaces/IWETHgateway.sol';

import "hardhat/console.sol";




contract RevengeOfTheFlash {

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

    IAaveProtocolDataProvider aaveProtocolDataProvider;



    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }


    address swaper0x;
    address revengeOfTheFlash;
    address offchainRelayer;

    
    
    



    function executeCont(
        ZrxQuote calldata _TUSDWETH_0x_quote
    ) public {
        //General variables
        uint tradedAmount;
        uint amountTokenOut;

        //0x - (TUSD to WETH)
        console.log('9. - WETH balance before TUSD swap: ', WETH.balanceOf(address(this)));

        // Structs0x.Order memory TUSDWETH_order = Structs0x.Order({
        //     makerAddress: offchainRelayer,               
        //     takerAddress: address(this),              
        //     feeRecipientAddress: 0x55662E225a3376759c24331a9aeD764f8f0C9FBb,    
        //     senderAddress: 0x0000000000000000000000000000000000000000,         
        //     makerAssetAmount: 224817300000000000000,        
        //     takerAssetAmount: 882693420471000000000000,           
        //     makerFee: 0,             
        //     takerFee: 0,              
        //     expirationTimeSeconds: 1620982324,           
        //     salt: 1620982124141785846,                   
        //     makerAssetData: "0xf47261b0000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",          
        //     takerAssetData: "0xf47261b00000000000000000000000000000000000085d4780b73119b644ae5ecd22b376"
        // });

        // exchange0xV2.fillOrder( 
        //     TUSDWETH_order, 
        //     882693246848885830100720,
        //     "0x1c822482f018fcea4b549c13f9cc9946967098189f5de8325b6413484b08ebf5694a32d92e764fb4319812c7242987d13cdb2d4448701e2b73f9c9fcfc34c6e79703"
        // );

        TUSD.transfer(offchainRelayer, 882693.24684888583010072 * 1 ether);
        (bool success, bytes memory returnData) = swaper0x.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                WETH, address(this), 224.817255779374783216 * 1 ether
            )
        );
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        require(success, 'TUSD/WETH withdrawal from pool failed');

        
        // (bool success, bytes memory returnData) = swaper0x.delegatecall(
        //     abi.encodeWithSignature('fillQuote(address,address,address,address,bytes)',
        //         _TUSDWETH_0x_quote.sellTokenAddress,
        //         _TUSDWETH_0x_quote.buyTokenAddress,
        //         _TUSDWETH_0x_quote.spender,
        //         _TUSDWETH_0x_quote.swapTarget,
        //         _TUSDWETH_0x_quote.swapCallData  
        //     )
        // );
        // if (!success) {
        //     console.log(Helpers._getRevertMsg(returnData));
        // }
        // require(success, 'TUSDWETH 0x swap failed');
        console.log('9. - WETH balance after TUSD swap: ', WETH.balanceOf(address(this)) / 1 ether);

        
        // UNISWAP - USDC to WBTC
        tradedAmount = sushiUniCro_swap(uniswapRouter, 44739 * 10 ** 6, USDC, WBTC, 0);
        console.log('10.- WBTC balance after swap (Uniswap): ', WBTC.balanceOf(address(this)) / 10 ** 8, '--', tradedAmount);

        // DODO (USDC to WBTC)
        address WBTCUSD_DODO_pool = 0x2109F78b46a789125598f5ad2b7f243751c2934d;
        tradedAmount = dodoSwapV1(WBTCUSD_DODO_pool, USDC, WBTC, 760574.389243 * 10 ** 6);
        console.log('11.- WBTC received after swap (DODO): ', tradedAmount / 10 ** 8, '--', tradedAmount);


        // 0x - (USDC to WBTC) -  
        USDC.transfer(offchainRelayer, 984272.740048 * 10 ** 6);
        (bool _success, bytes memory _returnData) = swaper0x.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                WBTC, address(this), (19.30930945 * 10 ** 8)
            )
        );
        if (!_success) {
            console.log(Helpers._getRevertMsg(_returnData));
        } else {
            (amountTokenOut) = abi.decode(_returnData, (uint256));
        }
        require(success, 'USDC/WBTC withdrawal from pool failed');

        console.log('12.- Amount of WBTC traded (0x - pool): ', amountTokenOut / 10 ** 8);
        console.log('___12.1.- WBTC balance after 0x swap (0x - 1Inch): ', WBTC.balanceOf(address(this)) / 10 ** 8);


        // BALANCER
        //(1st WBTC to ETH swap)
        tradedAmount = balancerSwapV1(balancerWBTCETHpool_1, 1.74806084 * 10 ** 8, WBTC, WETH);
        console.log('13.- Amount of WETH received (1st Balancer swap): ', tradedAmount / 1 ether);
        console.log('___13.1.- ETH balance after conversion from WETH: ', address(this).balance / 1 ether);

        //(2nd WBTC/ETH swap)
        tradedAmount = balancerSwapV1(balancerWBTCETHpool_2, 2.62209126 * 10 ** 8, WBTC, WETH);
        console.log('14.- Amount of WETH received (2nd Balancer swap): ', tradedAmount / 1 ether);
        console.log('___14.1.- ETH balance after conversion from WETH: ', address(this).balance / 1 ether);
        
        // UNISWAP - (WBTC to ETH)
        tradedAmount = sushiUniCro_swap(uniswapRouter, 3.49612169 * 10 ** 8, WBTC, WETH, 1);
        console.log('15.- Amount of ETH received (Uniswap): ', tradedAmount / 1 ether);

        // SUSHIWAP - (WBTC to ETH)
        tradedAmount = sushiUniCro_swap(sushiRouter, 7.42925859 * 10 ** 8, WBTC, WETH, 1);
        console.log('16.- Amount of ETH received (Sushiswap): ', tradedAmount / 1 ether);


        // 0x - (WBTC to WETH) - (using -deprecated- 1Inch protocol) 
        WBTC.transfer(offchainRelayer, WBTC.balanceOf(address(this)));
        (bool _success_, bytes memory _returnData_) = swaper0x.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                WETH, address(this), 253.071556591057205072 * 1 ether
            )
        );
        if (!_success_) {
            console.log(Helpers._getRevertMsg(_returnData_));
        } else {
            (amountTokenOut) = abi.decode(_returnData_, (uint));
        }
        require(success, 'USDC/WBTC withdrawal from pool failed');
        console.log('17.- WETH received (0x swap): ', amountTokenOut / 1 ether);


        // CURVE - (USDC to USDT)
        curveSwap(dai_usdc_usdt_Pool, USDC, 6263553.80031 * 10 ** 6, 1, 2, 0);
        console.log('18.- USDT balance after swap (Curve): ', USDT.balanceOf(address(this)) / 10 ** 6);

        // CRO Protocol (USDT to WETH)
        tradedAmount = sushiUniCro_swap(croDefiRouter, 78224.963477 * 10 ** 6, USDT, WETH);
        console.log('19.- WETH traded (CRO Protocol): ', tradedAmount / 1 ether);

        // 0x - (USDT to WETH) *******
        MySafeERC20.safeTransfer(USDT, offchainRelayer, 938699.561732 * 10 ** 6);
        tradedAmount = exchange.withdrawFromPool(WETH, address(this), 239.890714288415882321 * 1 ether);
        console.log('20.- WETH withdrawn from the Exchange (0x): ', tradedAmount / 1 ether);

        // SUSHISWAP - (USDT to ETH)
        tradedAmount = sushiUniCro_swap(sushiRouter, 2346748.904331 * 10 ** 6, USDT, WETH, 1);
        console.log('21. - SUSHIWAP --- ETH: ', tradedAmount / 1 ether);

        // UNISWAP - (USDT to ETH)
        tradedAmount = sushiUniCro_swap(uniswapRouter, 2894323.648676 * 10 ** 6, USDT, WETH, 1);
        console.log('22. - UNISWAP --- ETH: ', tradedAmount / 1 ether);

        // CRO Protocol (USDC to WETH)
        tradedAmount = sushiUniCro_swap(croDefiRouter, 100664.257504  * 10 ** 6, USDC, WETH);
        console.log('23.- CRO Protocol --- WETH: ', tradedAmount / 1 ether);

        // BALANCER - (USDC to ETH)
        tradedAmount = balancerSwapV1(balancerETHUSDCpool, 100664.257505 * 10 ** 6, USDC, WETH);
        console.log('24.- BALANCER --- ETH: ', tradedAmount / 1 ether);

        // DODO - (USDC to WETH)
        address WETHUSDC_DODO_pool = 0x75c23271661d9d143DCb617222BC4BEc783eff34;
        tradedAmount = dodoSwapV1(WETHUSDC_DODO_pool, USDC, WETH, 704649.802534 * 10 ** 6);
        console.log('25.- DODO --- WETH: ', tradedAmount / 1 ether);

        // 0x - (USDC to WETH) *****
        USDC.transfer(offchainRelayer, 905978.317545 * 10 ** 6);
        tradedAmount = exchange.withdrawFromPool(WETH, address(this), 231.15052891491875094 * 1 ether);
        console.log('26.- 0x (MyExchange) --- WETH: ', tradedAmount / 1 ether);

        // UNISWAP - (USDC to ETH)
        tradedAmount = sushiUniCro_swap(uniswapRouter, 2818599.21014 * 10 ** 6, USDC, WETH, 1);
        console.log('27.- UNISWAP --- ETH: ', tradedAmount / 1 ether);

        // SUSHISWAP - (USDC to ETH)
        tradedAmount = sushiUniCro_swap(sushiRouter, 3422584.755171 * 10 ** 6, USDC, WETH, 1);
        console.log('28.- SUSHISWAP --- ETH: ', tradedAmount / 1 ether);

        // Convert to ETH the remainder of WETH
        WETH_int.deposit{value: address(this).balance}();
        // WETH_int.withdraw(WETH.balanceOf(address(this)));
        // console.log('28.- WETH balance: ', WETH.balanceOf(address(this)) / 1 ether);
        // console.log('28.- ETH balance: ', address(this).balance / 1 ether);
        // aWETH 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e
        console.log('29.- WETH balance: ', WETH.balanceOf(address(this)) / 1 ether);

        // 1Inch Protocol
        // tradedAmount = oneInchSwap(address(0), USDC, address(this).balance);
        // console.log('29.- 1INCH Protocol --- USDC: ', tradedAmount / 10 ** 6);

        // AAVE - (supply ETH)
        lendingPoolAAVE.deposit(address(WETH), WETH.balanceOf(address(this)), address(this), 0);
        // console.log('hi');
        // lendingPoolAAVE.withdraw(address(WETH), 6478.183133980298798568 * 1 ether, address(this));
        // lendingPoolAAVE.borrow(address(WETH), 6478.183133980298798568 * 1 ether, 1, 0, address(this));

        // IWETHgateway ethGateway = IWETHgateway(0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04);
        // ethGateway.depositETH{value: address(this).balance}(address(lendingPoolAAVE), address(this), 0);
        // ethGateway.withdrawETH(address(lendingPoolAAVE), 6478 * 1 ether, address(this));


        // IAaveProtocolDataProvider aaveProtocolDataProvider = IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); 
        (uint a, uint b, uint c, uint d, uint e, uint f, uint g, uint40 h, bool i) =  aaveProtocolDataProvider.getUserReserveData(address(USDC), 0x278261c4545d65a81ec449945e83a236666B64F5);
        
        console.log(a);
        console.log(b);
        console.log(c);
        console.log(d);
        console.log(e);
        console.log(f);
        console.log(g);
        console.log(h);
        console.log(i);

        
        


        DataTypes.ReserveData memory USDCReservePoolAAVE = lendingPoolAAVE.getReserveData(address(USDC));
        address aTokenAddress = USDCReservePoolAAVE.aTokenAddress;
        console.log('aTokenAddress :', aTokenAddress);
        address variableDebtToken = USDCReservePoolAAVE.variableDebtTokenAddress;
        address stableDebtToken = USDCReservePoolAAVE.stableDebtTokenAddress;
        console.log('stable debt token: ', stableDebtToken);
        console.log('variable debt token: ', variableDebtToken);
        console.log('variable debt token balance: ', MyIERC20(variableDebtToken).balanceOf(address(this)) / 10 ** 6);
        console.log('stable debt token balance: ', MyIERC20(stableDebtToken).balanceOf(address(this)) / 10 ** 6);
        console.log('usdc debt token balance: ', MyIERC20(0x3b2a77058a1Eb4403a90b94585FaB16Bc512E703).balanceOf(address(this)) / 10 ** 6);
        

        // IAToken aToken = IAToken(0x1C050bCa8BAbe53Ef769d0d2e411f556e1a27E7B);
        // aToken.burn(address(this), address(this), MyIERC20(variableDebtToken).balanceOf(address(this)), 1040502722945288567833281785);


        console.log('--------------------------------------------------------');


        console.log('USDC balance: ', USDC.balanceOf(address(this)) / 10 ** 6);
        console.log('USDT balance: ', USDT.balanceOf(address(this)) / 10 ** 6);
        console.log('TUSD balance: ', TUSD.balanceOf(address(this)) / 1 ether);
        console.log('BNT balance: ', BNT.balanceOf(address(this)) / 1 ether);
        console.log('WBTC balance: ', WBTC.balanceOf(address(this)) / 10 ** 8);
        console.log('aWETH balance: ', aWETH.balanceOf(address(this)) / 1 ether);
        console.log('aUSDC balance: ', MyIERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C).balanceOf(address(this)));
        console.log('WETH balance: ', WETH.balanceOf(address(this)) / 1 ether);
        console.log('ETH balance: ', address(this).balance / 1 ether);

        
        // console.log('lending pool of the debt token: ', variableDebtToken.POOL());
        // 1007154214720821951861628637 index

    }


    



    


    function curveSwap(
        ICurve _pool,
        MyIERC20 _tokenIn, 
        uint _amountTokenIn, 
        int128 _numTokenIn, 
        int128 _numTokenOut,
        uint _dir
    ) public {
        _tokenIn.approve(address(_pool), _amountTokenIn);
        _dir == 1
            ?
        _pool.exchange_underlying(_numTokenIn, _numTokenOut, _amountTokenIn, 1)
            :
        _pool.exchange(_numTokenIn, _numTokenOut, _amountTokenIn, 1);
    }


    function dodoSwapV1(address _pool, MyIERC20 _tokenIn, MyIERC20 _tokenOut, uint _amount) private returns(uint) {
        address[] memory dodoPairs = new address[](1);
        dodoPairs[0] = _pool;
        address DODOapprove = 0xCB859eA579b28e02B87A1FDE08d087ab9dbE5149;
        _tokenIn.approve(DODOapprove, _amount);

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



    function oneInchSwap(address _tokenIn, MyIERC20 _tokenOut, uint _amount) private returns(uint) {
        // _tokenIn.approve(address(oneInch), type(uint).max);

        (uint expectedReturn, uint[] memory _distribution) = oneInch.getExpectedReturn(
            _tokenIn,
            _tokenOut,
            _amount,
            10,
            0
        );
        oneInch.swap{value: _amount}(_tokenIn, _tokenOut, _amount, 0, _distribution, 0);

        return expectedReturn;
    }


    function sushiUniCro_swap(
        ICroDefiSwapRouter02 _router, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut
    ) private returns(uint) {
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
    ) private returns(uint) {
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




    function balancerSwapV1(
        IBalancerV1 _pool, 
        uint _amount, 
        MyIERC20 _tokenIn, 
        MyIERC20 _tokenOut
    ) private returns(uint) {
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
}