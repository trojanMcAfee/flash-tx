//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;


import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/IAaveProtocolDataProvider.sol';
import '../interfaces/ICroDefiSwapRouter02.sol';
import '../interfaces/IWETHgateway.sol';
import '../interfaces/MyIERC20.sol';
import '../interfaces/ICurve.sol';
import '../libraries/MySafeERC20.sol';
import '../periphery/Helpers.sol';
import '../periphery/Exchange.sol';

import "hardhat/console.sol";




contract RevengeOfTheFlash is Ownable, Helpers {

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

    address myExchange;
    address revengeOfTheFlash;
    address offchainRelayer;



    function executeCont() public onlySecondaryOwner {
        //General variables
        uint tradedAmount;
        uint amountTokenOut;

        //MY EXCHANGE - (TUSD to WETH)
        TUSD.transfer(offchainRelayer, 882693.24684888583010072 * 1 ether);
        exchange.withdrawFromPool(WETH, address(this), 224.817255779374783216 * 1 ether);
        console.log('9. - myEXCHANGE --- WETH balance: ', WETH.balanceOf(address(this)) / 1 ether);

        // UNISWAP - USDC to WBTC
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                uniswapRouter, 44739 * 10 ** 6, USDC, WBTC, 0
            ), 
            'Uniswap USDC/WBTC',
            myExchange
        );
        console.log('10.- UNISWAP --- WBTC: ', WBTC.balanceOf(address(this)) / 10 ** 8, '--', tradedAmount);

        // DODO - (USDC to WBTC)
        address WBTCUSD_DODO_pool = 0x2109F78b46a789125598f5ad2b7f243751c2934d;
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'dodoSwapV1(address,address,address,uint256)', 
                WBTCUSD_DODO_pool, USDC, WBTC, 760574.389243 * 10 ** 6
            ), 
            'Dodo USDC/WBTC',
            myExchange
        );
        console.log('11.- DODO --- WBTC: ', tradedAmount / 10 ** 8, '--', tradedAmount);

        // MY EXCHANGE (other way) - (USDC to WBTC) - 
        USDC.transfer(offchainRelayer, 984272.740048 * 10 ** 6);
        (bool _success, bytes memory _returnData) = myExchange.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                WBTC, address(this), (19.30930945 * 10 ** 8)
            )
        );
        if (!_success) {
            console.log(_getRevertMsg(_returnData));
        } else {
            (amountTokenOut) = abi.decode(_returnData, (uint256));
        }
        require(_success, 'USDC/WBTC withdrawal from pool failed');

        console.log('12.- myEXCHANGE --- WBTC: ', amountTokenOut / 10 ** 8);
        console.log('___12.1.- WBTC balance after swap: ', WBTC.balanceOf(address(this)) / 10 ** 8);

        //BALANCER - (1st WBTC to ETH swap)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'balancerSwapV1(address,uint256,address,address)', 
                balancerWBTCETHpool_1, 1.74806084 * 10 ** 8, WBTC, WETH, 1
            ), 
            'Balancer WBTC/ETH (1)',
            myExchange
        );
        console.log('13.- BALANCER --- 1st WETH swap: ', tradedAmount / 1 ether);
        console.log('___13.1.- ETH balance after conversion from WETH: ', address(this).balance / 1 ether);

        //BALANCER - (2nd WBTC/ETH swap)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'balancerSwapV1(address,uint256,address,address)', 
                balancerWBTCETHpool_2, 2.62209126 * 10 ** 8, WBTC, WETH, 1
            ), 
            'Balancer WBTC/ETH (2)',
            myExchange
        );
        console.log('14.- BALANCER --- 2nd WETH swap: ', tradedAmount / 1 ether);
        console.log('___14.1.- ETH balance after conversion from WETH: ', address(this).balance / 1 ether);
        
        //UNISWAP - (WBTC to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                uniswapRouter, 3.49612169 * 10 ** 8, WBTC, WETH, 1
            ), 
            'Uniswap WBTC/ETH',
            myExchange
        );
        console.log('15.- UNISWAP -- ETH: ', tradedAmount / 1 ether);

        //SUSHIWAP - (WBTC to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                sushiRouter, 7.42925859 * 10 ** 8, WBTC, WETH, 1
            ), 
            'Sushiswap WBTC/ETH',
            myExchange
        );
        console.log('16.- SUSHISWAP --- ETH received: ', tradedAmount / 1 ether);

        // MY EXCHANGE (other way) - (WBTC to WETH) 
        WBTC.transfer(offchainRelayer, WBTC.balanceOf(address(this)));
        (bool _success_, bytes memory _returnData_) = myExchange.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                WETH, address(this), 253.071556591057205072 * 1 ether
            )
        );
        if (!_success_) {
            console.log(_getRevertMsg(_returnData_));
        } else {
            (amountTokenOut) = abi.decode(_returnData_, (uint));
        }
        require(_success_, 'USDC/WBTC withdrawal from pool failed');
        console.log('17.- myEXCHANGE --- WETH: ', amountTokenOut / 1 ether);

        // CURVE - (USDC to USDT)
        swapToExchange(
            abi.encodeWithSignature(
                'curveSwap(address,address,uint256,int128,int128,uint256)', 
                dai_usdc_usdt_Pool, USDC, 6263553.80031 * 10 ** 6, 1, 2, 0
            ), 
            'Curve USDC/USDT',
            myExchange
        );
        console.log('18.- CURVE --- USDT: ', USDT.balanceOf(address(this)) / 10 ** 6);

        // CRO Protocol - (USDT to WETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address)', 
                croDefiRouter, 78224.963477 * 10 ** 6, USDT, WETH
            ), 
            'CRO Protocol USDT/WETH',
            myExchange
        );
        console.log('19.- CRO Protocol - WETH: ', tradedAmount / 1 ether);

        // MY EXCHANGE - (USDT to WETH) 
        MySafeERC20.safeTransfer(USDT, offchainRelayer, 938699.561732 * 10 ** 6);
        tradedAmount = exchange.withdrawFromPool(WETH, address(this), 239.890714288415882321 * 1 ether);
        console.log('20.- myEXCHANGE --- WETH: ', tradedAmount / 1 ether);

        // SUSHISWAP - (USDT to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                sushiRouter, 2346748.904331 * 10 ** 6, USDT, WETH, 1
            ), 
            'Sushiswap USDT/ETH',
            myExchange
        );
        console.log('21. - SUSHIWAP --- ETH: ', tradedAmount / 1 ether);

        // UNISWAP - (USDT to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                uniswapRouter, 2894323.648676 * 10 ** 6, USDT, WETH, 1
            ), 
            'Uniswap USDT/ETH',
            myExchange
        );
        console.log('22. - UNISWAP --- ETH: ', tradedAmount / 1 ether);

        // CRO Protocol - (USDC to WETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address)', 
                croDefiRouter, 100664.257504  * 10 ** 6, USDC, WETH
            ), 
            'CRO Protocol USDC/WETH',
            myExchange
        );
        console.log('23.- CRO Protocol --- WETH: ', tradedAmount / 1 ether);

        // BALANCER - (USDC to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'balancerSwapV1(address,uint256,address,address)', 
                balancerETHUSDCpool, 100664.257505 * 10 ** 6, USDC, WETH
            ), 
            'Balancer USDC/ETH',
            myExchange
        );
        console.log('24.- BALANCER --- ETH: ', tradedAmount / 1 ether);

        // DODO - (USDC to WETH)
        address WETHUSDC_DODO_pool = 0x75c23271661d9d143DCb617222BC4BEc783eff34;
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'dodoSwapV1(address,address,address,uint256)', 
                WETHUSDC_DODO_pool, USDC, WETH, 704649.802534 * 10 ** 6
            ), 
            'Dodo USDC/WETH',
            myExchange
        );
        console.log('25.- DODO --- WETH: ', tradedAmount / 1 ether);

        // MY EXCHANGE - (USDC to WETH)
        USDC.transfer(offchainRelayer, 905978.317545 * 10 ** 6);
        tradedAmount = exchange.withdrawFromPool(WETH, address(this), 231.15052891491875094 * 1 ether);
        console.log('26.- myEXCHANGE --- WETH: ', tradedAmount / 1 ether);

        // UNISWAP - (USDC to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                uniswapRouter, 2818599.21014 * 10 ** 6, USDC, WETH, 1
            ), 
            'Uniswap USDC/ETH',
            myExchange
        );
        console.log('27.- UNISWAP --- ETH: ', tradedAmount / 1 ether);

        // SUSHISWAP - (USDC to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                sushiRouter, 3422584.755171 * 10 ** 6, USDC, WETH, 1
            ), 
            'Sushiswap USDC/ETH',
            myExchange
        );
        console.log('28.- SUSHISWAP --- ETH: ', tradedAmount / 1 ether);

        // Convert to ETH the remainder of WETH
        WETH_int.deposit{value: address(this).balance}();
        console.log('29.- WETH balance (flashlogic): ', WETH.balanceOf(address(this)) / 1 ether);

        // AAVE - (supply and withdraw WETH)
        lendingPoolAAVE.deposit(address(WETH), 4505.879348962757498457 * 1 ether, address(this), 0);
        lendingPoolAAVE.withdraw(address(WETH), 6478.183133980298798568 * 1 ether, address(this));

        //Sends WETH to DyDxFlashloaner to repay flashloan
        WETH.transferFrom(address(this), msg.sender, WETH.balanceOf(address(this)));
    
    }

}