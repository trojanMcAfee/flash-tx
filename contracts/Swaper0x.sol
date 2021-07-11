//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './libraries/Helpers.sol';
import 'hardhat/console.sol';



contract Swaper0x {

    // using Helpers for address;
    // using Helpers for uint;

    // function getRequestSELLBUY(
    //     address _sellToken, 
    //     address _buyToken,
    //     uint _buyAmount
    // ) internal pure returns (string memory) {
    //     string memory api0xUrl = 'https://api.0x.org/swap/v1/quote';
    //     string memory sellStr = '?sellToken=0x';
    //     string memory buyStr = '&buyToken=0x';
    //     string memory buyAmountStr = '&buyAmount=';


    //     return string(abi.encodePacked(
    //         api0xUrl, 
    //         sellStr,
    //         _sellToken._toAsciiString(),
    //         buyStr, 
    //         _buyToken._toAsciiString(), 
    //         buyAmountStr, 
    //         _buyAmount._uintToStr()));
    // }

    // function fillQuote(
    //     // The `sellTokenAddress` field from the API response.
    //     IERC20 sellToken,
    //     // The `buyTokenAddress` field from the API response.
    //     IERC20 buyToken,
    //     // The `allowanceTarget` field from the API response.
    //     address spender,
    //     // The `to` field from the API response.
    //     address payable swapTarget,
    //     // The `data` field from the API response.
    //     bytes calldata swapCallData
    // )
    //     external
    //     onlyOwner
    //     payable // Must attach ETH equal to the `value` field from the API response.
    // {
    //     // Track our balance of the buyToken to determine how much we've bought.
    //     uint256 boughtAmount = buyToken.balanceOf(address(this));

    //     // Give `spender` an infinite allowance to spend this contract's `sellToken`.
    //     // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
    //     // allowance to 0 before being able to update it.
    //     require(sellToken.approve(spender, uint256(-1)));
    //     // Call the encoded swap function call on the contract at `swapTarget`,
    //     // passing along any ETH attached to this function call to cover protocol fees.
    //     (bool success,) = swapTarget.call{value: msg.value}(swapCallData);
    //     require(success, 'SWAP_CALL_FAILED');
    //     // Refund any unspent protocol fees to the sender.
    //     msg.sender.transfer(address(this).balance);

    //     // Use our current buyToken balance to determine how much we've bought.
    //     boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
    //     emit BoughtTokens(sellToken, buyToken, boughtAmount);
    // }


    // function swap(
    //     uint256 paymentAmountInDai,
    //     address spender,             // API: "allowanceTarget"
    //     address swapTarget,          // API: "to"
    //     bytes calldata swapCallData  // API: "data"
    // ) internal view {

    //     console.log('hi9999');
        // WETH.deposit{value: msg.value}();

        // uint256 currentDaiBalance = DAI.balanceOf(address(this));
        // require(
        //     WETH.approve(spender, type(uint256).max),
        //     "approve failed"
        // );

        // (bool success, bytes memory res) = swapTarget.call(swapCallData);
        // require(
        //     success,
        //     string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg())))
        // );
        
        // msg.sender.transfer(address(this).balance);

        // uint256 boughtAmount = DAI.balanceOf(address(this)) - currentDaiBalance;
        // require(boughtAmount >= paymentAmountInDai, "INVALID_BUY_AMOUNT");
        
        // // may not be required?
        // uint256 daiRefund = boughtAmount - paymentAmountInDai;
        // DAI.transfer(msg.sender, daiRefund);
    // }

        // function toStringBytes(
        // uint256 v
        // ) internal pure returns (bytes memory) {
        //     if (v == 0) { return "0"; }

        //     uint256 j = v;
        //     uint256 len;

        //     while (j != 0) {
        //         len++;
        //         j /= 10;
        //     }

        //     bytes memory bstr = new bytes(len);
        //     uint256 k = len - 1;
            
        //     while (v != 0) {
        //         bstr[k--] = bytes32(uint8(48 + v % 10));
        //         v /= 10;
        //     }
            
        //     return bstr;
        // }



}