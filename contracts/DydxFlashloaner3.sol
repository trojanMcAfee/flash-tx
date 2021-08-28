//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./libraries/Helpers.sol";

import "hardhat/console.sol";


contract DydxFlashloaner3 is ICallee, DydxFlashloanBase {

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

    constructor(address _logicContract, uint _borrowed) public {
        logicContract = _logicContract;
        borrowed = _borrowed;
    }


    function _getZrxQuote(
        address[4][] memory _quotesAddr, 
        bytes[] memory _bytes,
        uint _index
    ) private returns(ZrxQuote memory) 
    {
        ZrxQuote memory zrxQuote = ZrxQuote({
            sellTokenAddress: _quotesAddr[_index][0],
            buyTokenAddress: _quotesAddr[_index][1],
            spender: _quotesAddr[_index][2],
            swapTarget: _quotesAddr[_index][3],
            swapCallData: _bytes[_index]
        });

        return zrxQuote;
    }


    // This is the function that will be called postLoan
    // i.e. Encode the logic to handle your flashloaned funds here
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        (
            MyCustomData memory mcd, 
            ZrxQuote memory USDCBNT_0x_quote,  
            ZrxQuote memory TUSDWETH_0x_quote,
            ZrxQuote memory USDCWBTC_0x_quote
        ) = abi.decode(
            data, 
            (MyCustomData, ZrxQuote, ZrxQuote, ZrxQuote)
        );
        uint256 balOfLoanedToken = IERC20(mcd.token).balanceOf(address(this));
        
        // Note that you can ignore the line below
        // if your dydx account (this contract in this case)
        // has deposited at least ~2 Wei of assets into the account
        // to balance out the collaterization ratio
        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );
        
        // TODO: Encode your logic here
        // E.g. arbitrage, liquidate accounts, etcx
        console.log('1.- Borrow WETH from dYdX (flashloan): ', (IERC20(mcd.token).balanceOf(address(this)) - 2 wei) / 1 ether);
        IERC20(mcd.token).transfer(logicContract, borrowed);
        executeCall(USDCBNT_0x_quote, TUSDWETH_0x_quote, USDCWBTC_0x_quote); 
    }

    function() external payable {}


    function executeCall(
        ZrxQuote memory _USDCBNT_0x_quote, 
        ZrxQuote memory _TUSDWETH_0x_quote,
        ZrxQuote memory _USDCWBTC_0x_quote
        ) private returns(uint, string memory) {

        (bool success, bytes memory data) = logicContract.call(
                abi.encodeWithSignature(
                    'execute(uint256,(address,address,address,address,bytes),(address,address,address,address,bytes),(address,address,address,address,bytes))',
                     borrowed, _USDCBNT_0x_quote, _TUSDWETH_0x_quote, _USDCWBTC_0x_quote
                )
        );
        if (!success) {
            // console.log(Helpers._getRevertMsg(data));
        }
        require(success, 'Call failed');
        return (0, '');
    }



    function initiateFlashLoan(
        address _solo, 
        address _token, 
        uint256 _amount, 
        address[4][] memory quotes_addr_0x,
        bytes[] memory quotes_bytes_0x
    ) public
    {
        ZrxQuote memory USDCBNT_0x_quote = _getZrxQuote(
            quotes_addr_0x,
            quotes_bytes_0x,
            0
        );        

        ZrxQuote memory TUSDWETH_0x_quote = _getZrxQuote(
            quotes_addr_0x,
            quotes_bytes_0x,
            1
        );

        ZrxQuote memory USDCWBTC_0x_quote = _getZrxQuote(
            quotes_addr_0x,
            quotes_bytes_0x,
            2
        );

        

        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            // Encode MyCustomData for callFunction
            abi.encode(
                MyCustomData({token: _token, repayAmount: repayAmount}), 
                USDCBNT_0x_quote, 
                TUSDWETH_0x_quote,
                USDCWBTC_0x_quote
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }
}