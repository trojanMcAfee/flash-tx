//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface MyIWETH {

    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function withdraw(uint256 wad) external;

}