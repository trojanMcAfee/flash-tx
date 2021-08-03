// // SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface MyIERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}