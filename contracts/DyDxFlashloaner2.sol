// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import './interfaces/MyIERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import './libraries/Helpers.sol';

import "hardhat/console.sol";



library Types {
    enum AssetDenomination { Wei, Par }
    enum AssetReference { Delta, Target }
    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

interface ICallee {
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external;
}

contract DyDxFlashloaner2 is ICallee {

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

    function _getZrxQuote(
        address[4][] memory _quotesAddr, 
        bytes[] memory _bytes,
        uint _index
    ) private pure returns(ZrxQuote memory) 
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

    IWETH private WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ISoloMargin private soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    constructor(address _logicContract, uint _borrowed) {
        WETH.approve(address(soloMargin), type(uint).max);
        logicContract = _logicContract;
        borrowed = _borrowed;
    }
    
    // This is the function we call
    function initiateFlashLoan(
        address _solo, 
        address _token, 
        uint256 _amount, 
        address[4][] memory quotes_addr_0x,
        bytes[] memory quotes_bytes_0x
    ) external {
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


        
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _amount // Amount to borrow
            }),
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        
        operations[1] = Actions.ActionArgs({
                actionType: Actions.ActionType.Call,
                accountId: 0,
                amount: Types.AssetAmount({
                    sign: false,
                    denomination: Types.AssetDenomination.Wei,
                    ref: Types.AssetReference.Delta,
                    value: 0
                }),
                primaryMarketId: 0,
                secondaryMarketId: 0,
                otherAddress: address(this),
                otherAccountId: 0,
                data: abi.encode(
                    MyCustomData({token: _token, repayAmount: _amount + 2}), 
                    USDCBNT_0x_quote, 
                    TUSDWETH_0x_quote,
                    USDCWBTC_0x_quote
                )
            });
        
        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _amount + 2 // Repayment amount with 2 wei fee
            }),
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        soloMargin.operate(accountInfos, operations);
    }
    
    // This is the function called by dydx after giving us the loan
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external override {
        // Decode the passed variables from the data object
        (
            MyCustomData memory mcd, 
            ZrxQuote memory USDCBNT_0x_quote,  
            ZrxQuote memory TUSDWETH_0x_quote,
            ZrxQuote memory USDCWBTC_0x_quote
        ) = abi.decode(
            data, 
            (MyCustomData, ZrxQuote, ZrxQuote, ZrxQuote)
        );
        uint256 balOfLoanedToken = MyIERC20(mcd.token).balanceOf(address(this));

        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );

        console.log('1.- Borrow WETH from dYdX (flashloan): ', (MyIERC20(mcd.token).balanceOf(address(this)) - 2 wei) / 1 ether);
        MyIERC20(mcd.token).transfer(logicContract, borrowed);
        executeCall(USDCBNT_0x_quote, TUSDWETH_0x_quote, USDCWBTC_0x_quote); 
    }


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
            console.log(Helpers._getRevertMsg(data));
            console.log('flashloan failed');
        }
        require(success, 'Call failed');
        return (0, '');
    }


    receive() external payable {}
}