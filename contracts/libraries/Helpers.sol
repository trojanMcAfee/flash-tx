//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0 <0.9.0;


// import '../Swaper0x.sol';
import "hardhat/console.sol";



library Helpers {

    // mapping(string => address) addresses;

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }


    function _createPath(address _token1, address _token2) public pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        return path;
    }


    // function swapToExchange(bytes memory _encodedData, string memory _swapDesc, Swaper0x swaper0x) external returns(uint tradedAmount) {
    //     (bool success, bytes memory returnData) = swaper0x.delegatecall(_encodedData);
    //     if (success && returnData.length > 0) {
    //         (tradedAmount) = abi.decode(returnData, (uint256));
    //     } else if (!success) {
    //         console.log(Helpers._getRevertMsg(returnData), '--', _swapDesc, 'failed');
    //         revert();
    //     }
    // }


    
    
    // function _adr(string memory _name) public view returns(address) {
    //     return addresses[_name];
    // }

    // function _toAsciiString(address x) internal pure returns (string memory) {
    //     bytes memory s = new bytes(40);
    //     for (uint i = 0; i < 20; i++) {
    //         bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
    //         bytes1 hi = bytes1(uint8(b) / 16);
    //         bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
    //         s[2*i] = _char(hi);
    //         s[2*i+1] = _char(lo);            
    //     }
    //         return string(s);
    // }


    // function _char(bytes1 b) internal pure returns (bytes1 c) {
    //     if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    //     else return bytes1(uint8(b) + 0x57);
    // }


    // function _uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
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