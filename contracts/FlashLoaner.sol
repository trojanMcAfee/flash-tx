//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/IDODOProxyV2.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/IBalancerV1.sol';
import './interfaces/ICurve.sol';
import './interfaces/I1inchProtocol.sol';
import './interfaces/IExchange0xV2.sol';
import {ICroDefiSwapPair, ICroDefiSwapRouter02} from './interfaces/ICroDefiSwapPair.sol';
// import './interfaces/ICroDefiSwapPair.sol';
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
    ICurve dai_usdc_usdt_Pool = ICurve(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IUniswapV2Router02 sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    I1inchProtocol oneInch = I1inchProtocol(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    IBancorNetwork bancorNetwork = IBancorNetwork(IContractRegistry(ContractRegistry_Bancor).addressOf('BancorNetwork'));
    IBalancerV1 balancerWBTCETHpool_1 = IBalancerV1(0x221BF20c2Ad9e5d7eC8a9d1991d8E2EdcfCb9d6c);
    IBalancerV1 balancerWBTCETHpool_2 = IBalancerV1(0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5);
    IDODOProxyV2 dodoProxyV2 = IDODOProxyV2(0xa356867fDCEa8e71AEaF87805808803806231FdC);
    IExchange0xV2 exchange0xV2 = IExchange0xV2(0x080bf510FCbF18b91105470639e9561022937712);
    ICroDefiSwapPair croDefiSwap = ICroDefiSwapPair(0x74C99F3f5331676f6AEc2756e1F39b4FC029a83E);
    ICroDefiSwapRouter02 croDefiRouter = ICroDefiSwapRouter02(0xCeB90E4C17d626BE0fACd78b79c9c87d7ca181b3);


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

        console.log('WETH balance of swaper0x: ', WETH.balanceOf(swaper0x), address(this) == swaper0x);

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
        USDC.transfer(0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9, 11184.9175 * 10 ** 6);
        (bool success, bytes memory returnData) = swaper0x.call(
            abi.encodeWithSignature(
                'withdrawFromPool(address,address,uint256)', 
                BNT, address(this), 1506.932141071984328329 * 1 ether
            )
        );
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        require(success, 'USDC/BNT withdrawal from pool failed');


        // (bool success, bytes memory returnData) = swaper0x.delegatecall(
        //     abi.encodeWithSignature('fillQuote(address,address,address,address,bytes)',
        //         _USDCBNT_0x_quote.sellTokenAddress,
        //         _USDCBNT_0x_quote.buyTokenAddress,
        //         _USDCBNT_0x_quote.spender,
        //         _USDCBNT_0x_quote.swapTarget,
        //         _USDCBNT_0x_quote.swapCallData 
        //     )
        // );
        // require(success, 'USDCBNT 0x swap failed');
        // if (!success) {
        //     console.log(Helpers._getRevertMsg(returnData));
        // }
        console.log('4.- BNT balance (swap 0x): ', BNT.balanceOf(address(this)) / 1 ether);


        //BANCOR 
        //(USDC to BNT swap)
        MyIERC20[] memory path;
        uint minReturn; 
        uint amount;
        path = bancorNetwork.conversionPath(USDC, BNT);
        amount = 883608.4825 * 10 ** 6; 
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
        amount = 894793.4 * 10 ** 6;
        yPool.exchange_underlying(1, 3, amount, 1);
        console.log('7.- TUSD balance (Curve swap): ', TUSD.balanceOf(address(this)) / 1 ether);

        // //SUSHISWAP (TUSD to ETH)
        TUSD.approve(address(sushiRouter), type(uint).max);
        amount = 11173.332238593491520262 * 1 ether;
        address[] memory _path;
        _path = Helpers._createPath(address(TUSD), address(WETH));
        uint[] memory tradedAmount;
        tradedAmount = sushiRouter.swapExactTokensForETH(amount, 0, _path, payable(address(this)), block.timestamp);
        console.log('8.- ETH traded (Sushiswap swap): ', tradedAmount[1] / 1 ether, '--', tradedAmount[1]);

        //Moving to Revenge
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






