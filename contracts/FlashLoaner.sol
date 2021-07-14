//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
// import './Swaper0x.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';

import "hardhat/console.sol";



contract FlashLoaner {
    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
        uint gas;
    }

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address public logicContract;
    // address public deployer;
    // address public chainlinkCallContract;
    uint public borrowed; 


    // function getDelegatedPrice(address _chainlinkCallContract, string memory _apiUrl) private returns (uint, string memory, bytes memory) {
    //     (bool success, bytes memory data) = _chainlinkCallContract.delegatecall(
    //         abi.encodeWithSignature('getData(string)', _apiUrl)
    //     );
    //     console.log(success);
    //     require(success, 'Second delegate call failed');  
    //     return (0, "", data);
    // }

    receive() external payable {}



    function execute(address _weth, address _contract, uint256 _borrowed, ZrxQuote calldata _zrxQuote) public {
        MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
        MyIERC20 weth = MyIERC20(_weth);
        address dYdXFlashloaner = _contract;

        MyIERC20 aWETH = MyIERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);
        // address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        // address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
        uint aaveUSDCloan = 100000 * 10 ** 18; //17895868 * 10 ** 6 --- change it to UNI from USDC just to test with a 18 decimals coin. That's why the var name differs
        
        console.log('hi');
        weth.approve(address(lendingPoolAAVE), _borrowed); //approves aave's liquidity pool for weth expenditure
        console.log('hi4');
        console.log('after execute is called: ', msg.sender);
        uint x = weth.balanceOf(msg.sender); // checks the msg.sender has the tokens to deposit
        console.log('WETH balance of msg.sender: ', x);
        console.log(msg.sender == dYdXFlashloaner);
        console.log('borrowed: ', _borrowed);
        console.log('reserves list: ', lendingPoolAAVE.getReservesList().length);  //checks that the interface is working fine 

        /*** Problem */
 
       try lendingPoolAAVE.deposit(_weth, _borrowed, msg.sender, 0) { //_weth, _borrowed, dYdXFlashloaner, 0
           console.log('success');
       } catch (bytes memory data) {
           (uint256 num) = abi.decode(data, (uint256));
           console.log('error number: ', num);
       }

       /*** Problem */
       
       console.log('aWETH balance: ', aWETH.balanceOf(msg.sender));
        console.log('hi2');
       lendingPoolAAVE.borrow(UNI, aaveUSDCloan, 2, 0, dYdXFlashloaner); //USDC
        console.log('hi3');
        uint usdcBalance = MyIERC20(UNI).balanceOf(dYdXFlashloaner); //USDC
        console.log('USDC balance: ', usdcBalance / 10 ** 18); //usdcBalance / 10 ** 6
        console.log('msg.sender on execute: ', msg.sender);

        

        fillQuote(
            _zrxQuote.sellTokenAddress,
            _zrxQuote.buyTokenAddress,
            _zrxQuote.spender,
            _zrxQuote.swapTarget,
            _zrxQuote.swapCallData,
            _zrxQuote.gas
        );

        
    }

    function fillQuote(
        // The `sellTokenAddress` field from the API response.
        address sellToken,
        // The `buyTokenAddress` field from the API response.
        address buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `to` field from the API response.
        address swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData, 
        uint gas
    ) private   
    {        
        console.log('sell token balance: ', MyIERC20(sellToken).balanceOf(address(this)));
        console.log('sell token balance of msg.sender: ', MyIERC20(sellToken).balanceOf(msg.sender));

        
        uint256 boughtAmount = MyIERC20(buyToken).balanceOf(address(this));
        
        require(MyIERC20(sellToken).approve(spender, type(uint).max));

        // console.logBytes(swapCallData);
        console.log('hi6');
        console.log('tx.origin: ', tx.origin);
        console.log('contract that calls the swap: ', address(this));
        console.log('ETH balance of the contract: ', address(this).balance);
        console.log('msg.value: ', msg.value);
        console.log('gas for the call: ', gas);
        console.log('msg.sender on fillQuote: ', msg.sender);
        console.log('spender (swapTarget): ', swapTarget);
        console.log('remaining gas: ', gasleft());
        (bool success, bytes memory returnData) = swapTarget.call{value: address(this).balance, gas: gas}(swapCallData);
        console.log(success);
        require(success, 'SWAP_CALL_FAILED');
        console.log('hi5');

        payable(msg.sender).transfer(address(this).balance);
        console.log(boughtAmount);
    }

    

    // function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    //     // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    //     if (_returnData.length < 68) return 'Transaction reverted silently';

    //     assembly {
    //         // Slice the sighash.
    //         _returnData := add(_returnData, 0x04)
    //     }
    //     return abi.decode(_returnData, (string)); // All that remains is the revert string
    // }

}



