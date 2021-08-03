//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './MyIERC20.sol';


interface IKyberRouter {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        MyIERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata poolsPath, MyIERC20[] calldata path, address to, uint256 deadline)
  external
  returns (uint256[] memory amounts);

  function weth() external pure returns (address);

}


interface IKyberFactory {

    function getUnamplifiedPool(MyIERC20 token0, MyIERC20 token1) external view returns (address);
    function getPools(MyIERC20 token0, MyIERC20 token1) external view returns (address[] memory _tokenPools);
    function allPoolsLength() external view returns (uint256);
}

interface IPoolWETHUSDT {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getTradeInfo() external view returns (
  uint112 _reserve0, uint112 _reserve1, uint112 _vReserve0, uint112 _vReserve1, uint256 feeInPrecision);
  function token0() external view returns (address);
  function token1() external view returns (address);
}