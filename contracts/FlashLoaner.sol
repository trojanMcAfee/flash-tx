pragma solidity 0.6.12;

// import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@aave/protocol-v2/contracts/interfaces/ILendingPool.sol';
// import './interfaces/MyILendingPool.sol';

import "hardhat/console.sol";

contract FlashLoaner {

    struct MyCustomData {
        address token;
        uint256 repayAmount;
    }

    address public logicContract;
    

    function execute(address _weth, address _contract) external view {
        console.log(_weth);
        uint num = IERC20(_weth).balanceOf(_contract);
        console.log(num);

        // supplyToAAVE();

        // MyILendingPool lendingPoolAAVE = MyILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

        // bool isTrue = lendingPoolAAVE.paused();
        // console.log(isTrue);
    }

}