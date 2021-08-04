//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import {IKyberRouter, IKyberFactory, IPoolWETHUSDT} from './interfaces/IKyber.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/IBalancerV1.sol';
import './interfaces/ICurve.sol';
import './interfaces/I1inchProtocol.sol';
import './libraries/Helpers.sol';
import './Swaper0x.sol'; 

import "hardhat/console.sol";


contract FlashLoaner {

    MyIERC20 USDT = MyIERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    MyIERC20 WBTC = MyIERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    MyIERC20 WETH = MyIERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    MyIERC20 USDC = MyIERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    MyIERC20 BNT = MyIERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    MyIERC20 TUSD = MyIERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    MyIERC20 ETH_Bancor = MyIERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IWETH WETH_int = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IContractRegistry ContractRegistry_Bancor = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    ICurve yPool = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    IUniswapV2Router02 sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    I1inchProtocol oneInch = I1inchProtocol(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    IBancorNetwork bancorNetwork = IBancorNetwork(IContractRegistry(ContractRegistry_Bancor).addressOf('BancorNetwork'));
    IKyberRouter kyberRouter = IKyberRouter(0x1c87257F5e8609940Bc751a07BB085Bb7f8cDBE6);
    IKyberFactory kyberFactory = IKyberFactory(0x833e4083B7ae46CeA85695c4f7ed25CDAd8886dE);
    IBalancerV1 balancerWBTCETHpool_1 = IBalancerV1(0x221BF20c2Ad9e5d7eC8a9d1991d8E2EdcfCb9d6c);
    IBalancerV1 balancerWBTCETHpool_2 = IBalancerV1(0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5);
    

    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }


    address swaper0x;
    address revengeOfTheFlash;


    constructor(address _swaper0x, address _revengeOfTheFlash) {
        swaper0x = _swaper0x;
        revengeOfTheFlash = _revengeOfTheFlash;
    }



    receive() external payable {}




    function execute(
        uint256 _borrowed, 
        ZrxQuote calldata _USDCBNT_0x_quote, 
        ZrxQuote calldata _TUSDWETH_0x_quote,
        ZrxQuote calldata _USDCWBTC_0x_quote
    ) public {
        

        //AAVE
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        WETH.approve(address(lendingPoolAAVE), _borrowed); 
        lendingPoolAAVE.deposit(address(WETH), _borrowed, address(this), 0); 
        console.log('2.- Deposit WETH to Aave: ', _borrowed / 1 ether);
        lendingPoolAAVE.borrow(address(USDC), aaveUSDCloan, 2, 0, address(this)); 
        
        uint usdcBalance = USDC.balanceOf(address(this)); 
        console.log('3.- USDC balance (borrow from AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        //(USDC to BNT)  
        (bool success, bytes memory returnData) = swaper0x.delegatecall(
            abi.encodeWithSignature('fillQuote(address,address,address,address,bytes)',
                _USDCBNT_0x_quote.sellTokenAddress,
                _USDCBNT_0x_quote.buyTokenAddress,
                _USDCBNT_0x_quote.spender,
                _USDCBNT_0x_quote.swapTarget,
                _USDCBNT_0x_quote.swapCallData 
            )
        );
        require(success, 'USDCBNT 0x swap failed');
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        console.log('4.- BNT balance (swap 0x): ', BNT.balanceOf(address(this)) / 1 ether);


        //BANCOR 
        //(USDC to BNT swap)
        MyIERC20[] memory path;
        uint minReturn; 
        uint amount;
        path = bancorNetwork.conversionPath(USDC, BNT);
        amount = 883608 * 10 ** 6; 
        minReturn = bancorNetwork.rateByPath(path, amount);
        USDC.approve(address(bancorNetwork), type(uint).max);

        uint bntTraded = bancorNetwork.convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('5.- Amount of BNT traded (swap Bancor)', bntTraded / 1 ether);
        console.log('___5.1.- BNT balance (after Bancor swap): ', BNT.balanceOf(address(this)) / 1 ether);

        //(BNT to ETH swap)
        path = bancorNetwork.conversionPath(BNT, ETH_Bancor);
        amount = BNT.balanceOf(address(this));
        minReturn = bancorNetwork.rateByPath(path, amount);
        BNT.approve(address(bancorNetwork), type(uint).max);

        bancorNetwork.convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('6.- ETH balance (2nd Bancor swap): ', address(this).balance / 1 ether); 

        //CURVE (USDC to TUSD)
        USDC.approve(address(yPool), type(uint).max);
        amount = 894793 * 10 ** 6;
        yPool.exchange_underlying(1, 3, amount, 1);
        console.log('7.- TUSD balance (Curve swap): ', TUSD.balanceOf(address(this)) / 1 ether);

        // //SUSHISWAP 
        TUSD.approve(address(sushiRouter), type(uint).max);
        amount = 11173 * 1 ether;
        address[] memory _path;
        _path = Helpers._createPath(address(TUSD), address(WETH));
        uint[] memory tradedAmount;
        tradedAmount = sushiRouter.swapExactTokensForETH(amount, 0, _path, payable(address(this)), block.timestamp);
        console.log('8.- ETH traded (Sushiswap swap): ', tradedAmount[1] / 1 ether, '--', tradedAmount[1]);

        // //0x
        // //(TUSD to WETH)
        (bool _success, bytes memory data) = revengeOfTheFlash.delegatecall(
            abi.encodeWithSignature('executeCont((address,address,address,address,bytes))',
             _TUSDWETH_0x_quote
            )
        );
        if (!_success) {
            console.log(Helpers._getRevertMsg(data));
        }
        require(_success, 'Delegatecall to Revenge of The Flash failed');

    }
    


}






