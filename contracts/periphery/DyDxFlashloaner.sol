// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/MyIERC20.sol';
import './Helpers.sol';

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
 

contract DyDxFlashloaner is ICallee, Ownable, Helpers {

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address soloDyDx = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address logicContract;
    uint borrowed;

    IWETH private WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ISoloMargin private soloMargin = ISoloMargin(soloDyDx);

    modifier onlySolo() {
        require(msg.sender == soloDyDx, 'Only DyDx can call this function');
        _;
    }

    constructor(address _logicContract, uint _borrowed) {
        WETH.approve(address(soloMargin), type(uint).max);
        logicContract = _logicContract;
        borrowed = _borrowed;
    }
    
    // This is the function we call
    function initiateFlashLoan(
        address _solo, 
        address _token, 
        uint256 _amount
    ) external onlyOwner {

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
                    MyCustomData({token: _token, repayAmount: _amount + 2})
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
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external override onlySolo {
        // Decode the passed variables from the data object
        ( MyCustomData memory mcd ) = abi.decode(
            data, 
            (MyCustomData)
        );
        uint256 balOfLoanedToken = MyIERC20(mcd.token).balanceOf(address(this));

        require(
            balOfLoanedToken >= mcd.repayAmount,
            "Not enough funds to repay dydx loan!"
        );

        console.log('1.- DYDX --- Borrow WETH (flashloan): ', (MyIERC20(mcd.token).balanceOf(address(this)) - 2 wei) / 1 ether);
        MyIERC20(mcd.token).transfer(logicContract, borrowed);
        executeCall(); 
    }


    function executeCall() private returns(uint, string memory) {
        (bool success, bytes memory data) = logicContract.call(
                abi.encodeWithSignature(
                    'execute(uint256)',
                     borrowed
                )
        );
        if (!success) console.log(_getRevertMsg(data));
        require(success, 'DyDx Flashloan failed');
        return (0, '');
    }


    receive() external payable {}
}