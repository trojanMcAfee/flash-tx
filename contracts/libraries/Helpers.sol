//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



abstract contract Helpers is Ownable {

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); 
    }


    function _createPath(address _token1, address _token2) internal pure returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
        return path;
    }


    function swapToExchange(bytes memory _encodedData, string memory _swapDesc, address _exchange) internal returns(uint tradedAmount) {
        (bool success, bytes memory returnData) = _exchange.delegatecall(_encodedData);
        if (success && returnData.length > 0) {
            (tradedAmount) = abi.decode(returnData, (uint256));
        } else if (!success) {
            console.log(Helpers._getRevertMsg(returnData), '--', _swapDesc, 'failed');
            revert();
        }
    }


    // function setSecondOwners(address _secondaryOwner1, address _secondaryOwner2) internal {
    //     _setSecondaryOwner(_secondaryOwner1);
    //     _setSecondaryOwner(_secondaryOwner2);
    // }
    
}