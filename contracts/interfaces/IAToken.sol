//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IAToken {

    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
  ) external;   

}