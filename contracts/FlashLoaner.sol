//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';
import './libraries/Helpers.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';

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

    address public logicContract;
    uint public borrowed;


    // receive() external payable {}


    function execute(address _weth, uint256 _borrowed, ZrxQuote calldata _zrxQuote) public {
        //AAVE
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 IWETH = MyIERC20(_weth);
        address USDC = _zrxQuote.sellTokenAddress;
        MyIERC20 IUSDC = MyIERC20(USDC); 
        uint aaveUSDCloan = 17895868 * 10 ** 6;

        IWETH.approve(address(lendingPoolAAVE), _borrowed); 
        lendingPoolAAVE.deposit(_weth, _borrowed, address(this), 0); 
       lendingPoolAAVE.borrow(USDC, aaveUSDCloan, 2, 0, address(this)); 
        
        uint usdcBalance = IUSDC.balanceOf(address(this)); 
        console.log('USDC balance (borrow AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        fillQuote(
            _zrxQuote.sellTokenAddress,
            _zrxQuote.buyTokenAddress,
            _zrxQuote.spender,
            _zrxQuote.swapTarget,
            _zrxQuote.swapCallData
        );   
        console.log('USDC balance (borrow AAVE): ', IUSDC.balanceOf(address(this)) / 10 ** 6);

        //BANCOR 
        //(USDC/BNT swap)
        IContractRegistry ContractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        MyIERC20 IBNT = MyIERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
        IBancorNetwork bancorNetwork = IBancorNetwork(ContractRegistry.addressOf('BancorNetwork'));
        address bancorNetworkAddr = ContractRegistry.addressOf('BancorNetwork');
        console.log('bancor network: ', bancorNetworkAddr);

        MyIERC20[] memory path = bancorNetwork.conversionPath(IUSDC, IBNT);
        uint amount = 883608 * 10 ** 6; 
        uint minReturn = bancorNetwork.rateByPath(path, amount); 
        IUSDC.approve(bancorNetworkAddr, type(uint).max);

        bancorNetwork.convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('BNT balance (swap Bancor): ', IBNT.balanceOf(address(this)) / 1 ether);

        //BNT 
        
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
        console.log('BNT balance (swap 0x): ', MyIERC20(buyToken).balanceOf(address(this)) / 10 ** 18);
    }
}



