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


    function execute(address _weth, uint256 _borrowed, ZrxQuote calldata _zrxQuote) public {
        //AAVE
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 weth = MyIERC20(_weth);
        address USDC = _zrxQuote.sellTokenAddress;
        MyIERC20 IUSDC = MyIERC20(USDC); 
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        address flashloaner = address(this);

        weth.approve(address(lendingPoolAAVE), _borrowed); 
        lendingPoolAAVE.deposit(_weth, _borrowed, flashloaner, 0); 
       lendingPoolAAVE.borrow(USDC, aaveUSDCloan, 2, 0, flashloaner); 
        
        uint usdcBalance = IUSDC.balanceOf(flashloaner); 
        console.log('USDC balance (borrow AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        fillQuote(
            _zrxQuote.sellTokenAddress,
            _zrxQuote.buyTokenAddress,
            _zrxQuote.spender,
            _zrxQuote.swapTarget,
            _zrxQuote.swapCallData
        );   

        //BANCOR
        IContractRegistry ContractRegistry = IContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
        MyIERC20 IBNT = MyIERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
        IBancorNetwork bancorNetwork = IBancorNetwork(ContractRegistry.addressOf('BancorNetwork'));

        address[] memory path = bancorNetwork.conversionPath(IUSDC, IBNT);
        console.log('balance of USDC :', (IUSDC.balanceOf(address(this))) / 10 ** 6);
        uint num = 883608 * 1 ether;
        uint rate = bancorNetwork.rateByPath(path, num); //doing the swap of USDC for BNT
        // IbancorNetwork.convertByPath()
        console.log(rate / 1 ether);
        

        
    //     function convertByPath(
    //     address[] memory _path, 
    //     uint256 _amount, 
    //     uint256 _minReturn, 
    //     address _beneficiary, 
    //     address _affiliateAccount, 
    //     uint256 _affiliateFee
    // ) external payable returns (uint256);

    // function rateByPath(
    //     address[] memory _path, 
    //     uint256 _amount
    // ) external view returns (uint256);

        
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
        console.log('BNT balance after swap (swap 0x): ', MyIERC20(buyToken).balanceOf(address(this)) / 10 ** 12);
    }
}



