//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/ICurve.sol';
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

    // constructor() {
    //     addresses['USDC'] = _zrxQuote.sellTokenAddress;
    //     addresses['BNT'] = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    //     addresses['TUSD'] = 0x0000000000085d4780B73119b644AE5ecd22b376;
    // }

    address public logicContract;
    uint public borrowed;

    mapping(string => address) public addresses;
    mapping(string => MyIERC20) public test2;

    mapping(string => mapping(address => MyIERC20)) test; //trying to create a struct inside a mapping for the addresses and interfaces so they occupy less space

    receive() external payable {}


    function execute(address _weth, uint256 _borrowed, ZrxQuote calldata _zrxQuote) public {
        addresses['USDC'] = _zrxQuote.sellTokenAddress;
        addresses['BNT'] = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
        addresses['TUSD'] = 0x0000000000085d4780B73119b644AE5ecd22b376;

        //General variables
        MyIERC20 IWETH = MyIERC20(_weth); 
        // address USDC = _zrxQuote.sellTokenAddress;
        MyIERC20 IUSDC = MyIERC20(addresses['USDC']);
        // address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
        MyIERC20 IBNT = MyIERC20(addresses['BNT']);
        // address TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
        MyIERC20 ITUSD = MyIERC20(addresses['TUSD']);

    
        // struct test {

        // }

        //AAVE
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        uint aaveUSDCloan = 17895868 * 10 ** 6;

        IWETH.approve(address(lendingPoolAAVE), _borrowed); 
        lendingPoolAAVE.deposit(_weth, _borrowed, address(this), 0); 
        console.log('2.- Deposit WETH to Aave: ', _borrowed / 1 ether);
       lendingPoolAAVE.borrow(addresses['USDC'], aaveUSDCloan, 2, 0, address(this)); 
        
        uint usdcBalance = IUSDC.balanceOf(address(this)); 
        console.log('3.- USDC balance (borrow from AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        fillQuote(
            _zrxQuote.sellTokenAddress,
            _zrxQuote.buyTokenAddress,
            _zrxQuote.spender,
            _zrxQuote.swapTarget,
            _zrxQuote.swapCallData
        );   

        //BANCOR 
        //(USDC to BNT swap)
        IContractRegistry ContractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        IBancorNetwork bancorNetwork = IBancorNetwork(ContractRegistry.addressOf('BancorNetwork'));

        MyIERC20[] memory path;
        uint minReturn; 
        uint amount;
        path = bancorNetwork.conversionPath(IUSDC, IBNT);
        amount = 883608 * 10 ** 6; 
        minReturn = bancorNetwork.rateByPath(path, amount);
        IUSDC.approve(address(bancorNetwork), type(uint).max);

        uint bntTraded = bancorNetwork.convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('5.- Amount of BNT traded (swap Bancor)', bntTraded / 1 ether);
        console.log('___5.1.- BNT balance (after Bancor swap): ', IBNT.balanceOf(address(this)) / 1 ether);

        //(BNT to ETH swap)
        MyIERC20 BETH = MyIERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        path = bancorNetwork.conversionPath(IBNT, BETH);

        amount = IBNT.balanceOf(address(this));
        minReturn = bancorNetwork.rateByPath(path, amount);
        IBNT.approve(address(bancorNetwork), type(uint).max);

        bancorNetwork.convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('6.- ETH balance (2nd Bancor swap): ', address(this).balance / 1 ether); 

        //CURVE
        ICurve yPool = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
        IUSDC.approve(address(yPool), type(uint).max);
        amount = 894793 * 10 ** 6;
        yPool.exchange_underlying(1, 3, amount, 1);
        console.log('7.- TUSD balance (Curve swap): ', ITUSD.balanceOf(address(this)) / 1 ether);

        //SUSHISWAP 
        // IUniswapV2Router02 sushiRouter = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        // amount = 11173 * 1 ether;
        // address[] memory _path = new address[](2);
        // _path[0] = TUSD;
        // _path[1] = _weth;
        // uint[] memory _amount = sushiRouter.swapExactTokensForTokens(amount, 0, _path, address(this), block.timestamp);
        // console.log('WETH balance: ', IWETH.balanceOf(address(this)));
        // console.log('ETH balance: ', address(this).balance);
        // for (uint i = 0; i < _amount.length; i++) {
        //     console.log(_amount[i]);
        // }

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
        console.log('4.- BNT balance (swap 0x): ', MyIERC20(buyToken).balanceOf(address(this)) / 1 ether);
    }
}



