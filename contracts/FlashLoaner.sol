//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './Swaper0x.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';

import "hardhat/console.sol";

contract FlashLoaner is Swaper0x {

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address public logicContract;
    address public deployer;
    address public chainlinkCallContract;
    uint public borrowed;


    function getDelegatedPrice(address _chainlinkCallContract, string memory _apiUrl) private returns (uint, string memory, bytes memory) {
        (bool success, bytes memory data) = _chainlinkCallContract.delegatecall(
            abi.encodeWithSignature('getData(string)', _apiUrl)
        );
        console.log(success);
        require(success, 'Second delegate call failed');  
        return (0, "", data);
    }



    function execute(address _weth, address _contract, uint256 _borrowed, address _chainlinkCallContract) external {

        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 weth = MyIERC20(_weth);
        address dYdXFlashloaner = _contract;

        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        uint usdcToSell = 11184.9175 * 10 ** 18;

        weth.approve(address(lendingPoolAAVE), _borrowed);
       lendingPoolAAVE.deposit(_weth, _borrowed, dYdXFlashloaner, 0);
       lendingPoolAAVE.borrow(USDC, aaveUSDCloan, 2, 0, dYdXFlashloaner);

        uint usdcBalance = MyIERC20(USDC).balanceOf(dYdXFlashloaner);
        console.log('USDC balance: ', usdcBalance / 10 ** 6);

        string memory apiURL = getRequestSELLBUY(USDC, BNT, usdcToSell);
        (, , bytes memory data) = getDelegatedPrice(_chainlinkCallContract, apiURL);
        (uint price0xCall) = abi.decode(data, (uint));
        console.log(price0xCall);
        
    }

}

