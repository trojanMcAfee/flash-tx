//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";



contract DydxFlashloaner is ICallee, DydxFlashloanBase {
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

    constructor(address _logicContract, uint _borrowed) public {
        logicContract = _logicContract;
        borrowed = _borrowed;
        // chainlinkCallContract = _chainlinkCallContract;
    }

    function() external payable {}


    // This is the function that will be called postLoan
    // i.e. Encode the logic to handle your flashloaned funds here
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {
        (MyCustomData memory mcd, ZrxQuote memory zrx) = abi.decode(data, (MyCustomData, ZrxQuote));
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
        IERC20(mcd.token).transfer(logicContract, borrowed);
        executeDelegate(mcd.token, address(this), zrx); 
    }


    function executeDelegate(address _weth, address _contract, ZrxQuote memory _zrxQuote) private returns(uint, string memory) {
        console.log('on execute delegate: ', msg.sender);
        (bool success, bytes memory data) = logicContract.call(
                abi.encodeWithSignature(
                    'execute(address,address,uint256,(address,address,address,address,bytes,uint256))',
                     _weth, _contract, borrowed, _zrxQuote
                )
        );
        if (!success) {
            console.log(_getRevertMsg(data));
        }
        require(success, 'Delegate Call failed');
        return (0, '');
    }


    function initiateFlashLoan(
        address _solo, 
        address _token, 
        uint256 _amount, 
        address[] calldata _quoteAddr, 
        bytes calldata _quoteData,
        uint _gas 
    ) external
    {
        ZrxQuote memory zrxQuote = ZrxQuote({
            sellTokenAddress: _quoteAddr[0],
            buyTokenAddress: _quoteAddr[1],
            spender: _quoteAddr[2],
            swapTarget: _quoteAddr[3],
            swapCallData: _quoteData,
            gas: _gas
        });

        console.log('on initiate: ', msg.sender);
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
            abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}), zrxQuote)
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }
    

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}