//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './libraries/Helpers.sol';
import 'hardhat/console.sol';



contract Swaper0x {

    using Helpers for address;
    using Helpers for uint;

    function getRequestSELLBUY(
        address _sellToken, 
        address _buyToken,
        uint _buyAmount
    ) internal pure returns (string memory) {
        string memory api0xUrl = 'https://api.0x.org/swap/v1/quote';
        string memory sellStr = '?sellToken=0x';
        string memory buyStr = '&buyToken=0x';
        string memory buyAmountStr = '&buyAmount=';


        return string(abi.encodePacked(
            api0xUrl, 
            sellStr,
            _sellToken._toAsciiString(),
            buyStr, 
            _buyToken._toAsciiString(), 
            buyAmountStr, 
            _buyAmount._uintToStr()));
    }


    function swap(
        uint256 paymentAmountInDai,
        address spender,             // API: "allowanceTarget"
        address swapTarget,          // API: "to"
        bytes calldata swapCallData  // API: "data"
    ) internal view {

        console.log('hi2');
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
    }

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



        // function _toAsciiString(address x) private pure returns (string memory) {
        // bytes memory s = new bytes(40);
        // for (uint i = 0; i < 20; i++) {
        //     bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        //     bytes1 hi = bytes1(uint8(b) / 16);
        //     bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        //     s[2*i] = _char(hi);
        //     s[2*i+1] = _char(lo);            
        // }
        //     return string(s);
        // }

        // function _char(bytes1 b) private pure returns (bytes1 c) {
        //     if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        //     else return bytes1(uint8(b) + 0x57);
        // }

        // function _uintToStr(uint _i) private pure returns (string memory _uintAsString) {
        //     if (_i == 0) {
        //         return "0";
        //     }
        //     uint j = _i;
        //     uint len;
        //     while (j != 0) {
        //         len++;
        //         j /= 10;
        //     }
        //     bytes memory bstr = new bytes(len);
        //     uint k = len;
        //     while (_i != 0) {
        //         k = k-1;
        //         uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        //         bytes1 b1 = bytes1(temp);
        //         bstr[k] = b1;
        //         _i /= 10;
        //     }
        //     return string(bstr);
        // }

}