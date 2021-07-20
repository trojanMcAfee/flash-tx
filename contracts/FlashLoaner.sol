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

    // mapping(string => address) addresses;

    // constructor() {
    //     addresses['USDC'] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //     addresses['BNT'] = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    //     addresses['TUSD'] = 0x0000000000085d4780B73119b644AE5ecd22b376;
    //     addresses['lendingPoolAAVE'] = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    //     addresses['ContractRegistry_Bancor'] = 0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4;
    //     addresses['bancorNetwork'] = IContractRegistry(ContractRegistry_Bancor).addressOf('BancorNetwork');
    //     addresses['ETH_Bancor'] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //     addresses['yPool'] = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    // } 


    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    address TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address lendingPoolAAVE = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address ContractRegistry_Bancor = 0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4;
    address bancorNetwork = IContractRegistry(ContractRegistry_Bancor).addressOf('BancorNetwork');
    address ETH_Bancor = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address yPool = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;


    receive() external payable {}

    // function _adr(string memory _name) internal view returns (address) {
    //     return addresses[_name];
    // }


    //do the 0x swap of _TUSDWETH_0x_quote and see if the decimals is the problem
    function execute(address _weth, uint256 _borrowed, ZrxQuote calldata _USDCBNT_0x_quote, ZrxQuote calldata _TUSDWETH_0x_quote) public {
        //General variables
        MyIERC20 IWETH = MyIERC20(_weth); 
        

        //AAVE
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        IWETH.approve(lendingPoolAAVE, _borrowed); 
        MyILendingPool(lendingPoolAAVE).deposit(_weth, _borrowed, address(this), 0); 
        console.log('2.- Deposit WETH to Aave: ', _borrowed / 1 ether);
        MyILendingPool(lendingPoolAAVE).borrow(USDC, aaveUSDCloan, 2, 0, address(this)); 
        
        uint usdcBalance = MyIERC20(USDC).balanceOf(address(this)); 
        console.log('3.- USDC balance (borrow from AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        //(USDC to BNT)
        fillQuote(
            _USDCBNT_0x_quote.sellTokenAddress,
            _USDCBNT_0x_quote.buyTokenAddress,
            _USDCBNT_0x_quote.spender,
            _USDCBNT_0x_quote.swapTarget,
            _USDCBNT_0x_quote.swapCallData
        );   

        //BANCOR 
        //(USDC to BNT swap)
        MyIERC20[] memory path;
        uint minReturn; 
        uint amount;
        path = IBancorNetwork(bancorNetwork).conversionPath(MyIERC20(USDC), MyIERC20(BNT));
        amount = 883608 * 10 ** 6; 
        minReturn = IBancorNetwork(bancorNetwork).rateByPath(path, amount);
        MyIERC20(USDC).approve(bancorNetwork, type(uint).max);

        uint bntTraded = IBancorNetwork(bancorNetwork).convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('5.- Amount of BNT traded (swap Bancor)', bntTraded / 1 ether);
        console.log('___5.1.- BNT balance (after Bancor swap): ', MyIERC20(BNT).balanceOf(address(this)) / 1 ether);

        //(BNT to ETH swap)
        path = IBancorNetwork(bancorNetwork).conversionPath(MyIERC20(BNT), MyIERC20(ETH_Bancor));
        amount = MyIERC20(BNT).balanceOf(address(this));
        minReturn = IBancorNetwork(bancorNetwork).rateByPath(path, amount);
        MyIERC20(BNT).approve(bancorNetwork, type(uint).max);

        IBancorNetwork(bancorNetwork).convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('6.- ETH balance (2nd Bancor swap): ', address(this).balance / 1 ether); 

        //CURVE
        MyIERC20(USDC).approve(yPool, type(uint).max);
        amount = 894793 * 10 ** 6;
        ICurve(yPool).exchange_underlying(1, 3, amount, 1);
        console.log('7.- TUSD balance (Curve swap): ', MyIERC20(TUSD).balanceOf(address(this)) / 1 ether);

        //SUSHISWAP 
        MyIERC20(TUSD).approve(sushiRouter, type(uint).max);
        amount = 11173 * 1 ether;
        address[] memory _path = new address[](2);
        _path[0] = TUSD;
        _path[1] = _weth;
        uint[] memory _amount = IUniswapV2Router02(sushiRouter).swapExactTokensForETH(amount, 0, _path, payable(address(this)), block.timestamp);
        console.log('8.- ETH traded (Sushiswap swap): ', _amount[1] / 1 ether, ' - raw: ', _amount[1]);

        //0x
        //(TUSDC to WETH)
        
        
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



