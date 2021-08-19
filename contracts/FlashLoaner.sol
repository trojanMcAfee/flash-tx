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
import './interfaces/ICroDefiSwapRouter02.sol';
import './libraries/Helpers.sol';
import './Swaper0x.sol'; 

// import './interfaces/IDebtTokenAAVE/IVariableDebtToken.sol';
import './interfaces/IConnectAAVE.sol';
import './interfaces/IAaveProtocolDataProvider.sol';

import "hardhat/console.sol";


contract FlashLoaner {

    MyIERC20 USDT = MyIERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    MyIERC20 WBTC = MyIERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    MyIERC20 WETH = MyIERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    MyIERC20 USDC = MyIERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    MyIERC20 BNT = MyIERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    MyIERC20 TUSD = MyIERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    MyIERC20 ETH = MyIERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
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
    IBalancerV1 balancerETHUSDCpool = IBalancerV1(0x8a649274E4d777FFC6851F13d23A86BBFA2f2Fbf);
    IDODOProxyV2 dodoProxyV2 = IDODOProxyV2(0xa356867fDCEa8e71AEaF87805808803806231FdC);
    IExchange0xV2 exchange0xV2 = IExchange0xV2(0x080bf510FCbF18b91105470639e9561022937712);
    ICroDefiSwapRouter02 croDefiRouter = ICroDefiSwapRouter02(0xCeB90E4C17d626BE0fACd78b79c9c87d7ca181b3);
    Swaper0x exchange;
    MyIERC20 aWETH = MyIERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e); //0x541dCd3F00Bcd1A683cc73E1b2A8693b602201f4

    IAaveProtocolDataProvider aaveProtocolDataProvider = IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); 
    

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
    address offchainRelayer;



    constructor(address _swaper0x, address _revengeOfTheFlash, address _offchainRelayer) {
        swaper0x = _swaper0x;
        revengeOfTheFlash = _revengeOfTheFlash;
        offchainRelayer = _offchainRelayer;
    }


    function setExchange(Swaper0x _swaper0x) public {
        exchange = _swaper0x;
    }



    receive() external payable {}


 

    function swapToExchange(bytes memory _encodedData, string memory _swapDesc) private returns(uint tradedAmount) {
        (bool success, bytes memory returnData) = swaper0x.delegatecall(_encodedData);
        if (success && returnData.length > 0) {
            (tradedAmount) = abi.decode(returnData, (uint256));
        } else if (!success) {
            console.log(Helpers._getRevertMsg(returnData), '--', _swapDesc, 'failed');
            revert();
        }

    }



    function execute(
        uint256 _borrowed, 
        ZrxQuote calldata _USDCBNT_0x_quote, 
        ZrxQuote calldata _TUSDWETH_0x_quote,
        ZrxQuote calldata _USDCWBTC_0x_quote
    ) public {

        address callerContract = 0x278261c4545d65a81ec449945e83a236666B64F5;



        console.log('USDC balance: ', USDC.balanceOf(callerContract) / 10 ** 6);
        console.log('USDT balance: ', USDT.balanceOf(callerContract) / 10 ** 6);
        console.log('TUSD balance: ', TUSD.balanceOf(callerContract) / 1 ether);
        console.log('BNT balance: ', BNT.balanceOf(callerContract) / 1 ether);
        console.log('WBTC balance: ', WBTC.balanceOf(callerContract) / 10 ** 8);
        console.log('aWETH balance: ', aWETH.balanceOf(callerContract) / 1 ether);
        console.log('WETH balance (caller): ', WETH.balanceOf(callerContract) / 1 ether);
        console.log('WETH balance (address(this)): ', WETH.balanceOf(address(this)) / 1 ether);
        console.log('ETH balance: ', callerContract.balance / 1 ether);

        bool success;
        bytes memory returnData;
        uint tradedAmount;


        //AAVE
        uint usdcWithdrawal = 17895868 * 10 ** 6;
        WETH.approve(address(lendingPoolAAVE), type(uint).max); 
        lendingPoolAAVE.deposit(address(WETH), _borrowed, address(this), 0); 
        console.log('2.- Deposit WETH to Aave: ', _borrowed / 1 ether);

        // lendingPoolAAVE.borrow(address(USDC), usdcWithdrawal, 1, 0, address(this));
        lendingPoolAAVE.withdraw(address(USDC), usdcWithdrawal, address(this)); 
        uint usdcBalance = USDC.balanceOf(address(this)); 
        console.log('3.- USDC balance (borrow from AAVE): ', usdcBalance / 10 ** 6); 

        
        //0x
        //(USDC to BNT)
        USDC.transfer(offchainRelayer, 11184.9175 * 10 ** 6);
        (success, returnData) = swaper0x.call(
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
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'bancorSwap(address,address,uint256)', 
                USDC, BNT, 883608.4825 * 10 ** 6
            ), 
            'Bancor USDC/BNT'
        );
        console.log('5.- Amount of BNT traded (swap Bancor)', tradedAmount / 1 ether);
        console.log('___5.1.- BNT balance (after Bancor swap): ', BNT.balanceOf(address(this)) / 1 ether);

        //(BNT to ETH swap)
        swapToExchange(
            abi.encodeWithSignature(
                'bancorSwap(address,address,uint256)', 
                BNT, ETH, BNT.balanceOf(address(this))
            ), 
            'Bancor BNT/ETH'
        );
        console.log('6.- ETH balance (2nd Bancor swap): ', address(this).balance / 1 ether); 

        //CURVE - (USDC to TUSD)
        swapToExchange(
            abi.encodeWithSignature(
                'curveSwap(address,address,uint256,int128,int128,uint256)', 
                yPool, USDC, 894793.4 * 10 ** 6, 1, 3, 1
            ), 
            'Curve USDC/TUSD' 
        );
        console.log('7.- TUSD balance (Curve swap): ', TUSD.balanceOf(address(this)) / 1 ether);

        // //SUSHISWAP - (TUSD to ETH)
        tradedAmount = swapToExchange(
            abi.encodeWithSignature(
                'sushiUniCro_swap(address,uint256,address,address,uint256)', 
                sushiRouter, 11173.332238593491520262 * 1 ether, TUSD, WETH, 1
            ), 
            'Sushiswap TUSD/ETH'
        );
        console.log('8.- ETH traded (Sushiswap swap): ', tradedAmount / 1 ether, '--', tradedAmount);

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






