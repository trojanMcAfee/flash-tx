//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';

import "hardhat/console.sol";

contract FlashLoaner {

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address public logicContract;
    address public deployer;
    uint public borrowed;
    

    function execute(address _weth, address _contract, uint256 _borrowed) external {

        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 weth = MyIERC20(_weth);
        address usdcAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        address dYdXFlashloaner = _contract;

        weth.approve(address(lendingPoolAAVE), _borrowed);

       lendingPoolAAVE.deposit(_weth, _borrowed, dYdXFlashloaner, 0);

       lendingPoolAAVE.borrow(usdcAddr, aaveUSDCloan, 2, 0, dYdXFlashloaner);

        address aWETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
        // uint usdcBalance = MyIERC20(usdcAddr).balanceOf(dYdXFlashloaner);
        // console.log('USDC balance: ', usdcBalance / 10 ** 6);
    }

}