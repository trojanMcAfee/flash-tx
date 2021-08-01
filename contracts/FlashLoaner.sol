//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IContractRegistry, IBancorNetwork} from './interfaces/IBancor.sol';
import './interfaces/MyILendingPool.sol';
import './interfaces/MyIERC20.sol';
import './interfaces/ICurve.sol';
import './libraries/Helpers.sol';
import './Swaper0x.sol'; 

import "hardhat/console.sol";


contract FlashLoaner {

    struct ZrxQuote {
        address sellTokenAddress;
        address buyTokenAddress;
        address spender;
        address swapTarget;
        bytes swapCallData;
    }


    mapping(string => address) addresses;

    address swaper0x;
    address revengeOfTheFlash;


    constructor(
        address _swaper0x, 
        address _revengeOfTheFlash,
        string[] memory _addrNames,
        address[] memory _addresses) 
    {
        swaper0x = _swaper0x;
        revengeOfTheFlash = _revengeOfTheFlash;

        for (uint i = 0; i < _addrNames.length; i++) {
            addresses[_addrNames[i]] = _addresses[i];
        }
        addresses['bancorNetwork'] = IContractRegistry(addresses['ContractRegistry_Bancor']).addressOf('BancorNetwork');
    }


    function _adr(string memory _name) private view returns(address) {
        return addresses[_name];
    }


    receive() external payable {}




    function execute(
        uint256 _borrowed, 
        ZrxQuote calldata _USDCBNT_0x_quote, 
        ZrxQuote calldata _TUSDWETH_0x_quote,
        ZrxQuote calldata _USDCWBTC_0x_quote
    ) public {
        

        //AAVE
        uint aaveUSDCloan = 17895868 * 10 ** 6;
        MyIERC20(_adr('WETH')).approve(_adr('lendingPoolAAVE'), _borrowed); 
        MyILendingPool(_adr('lendingPoolAAVE')).deposit(_adr('WETH'), _borrowed, address(this), 0); 
        console.log('2.- Deposit WETH to Aave: ', _borrowed / 1 ether);
        MyILendingPool(_adr('lendingPoolAAVE')).borrow(_adr('USDC'), aaveUSDCloan, 2, 0, address(this)); 
        
        uint usdcBalance = MyIERC20(_adr('USDC')).balanceOf(address(this)); 
        console.log('3.- USDC balance (borrow from AAVE): ', usdcBalance / 10 ** 6); 

        //0x
        //(USDC to BNT)  
        (bool success, bytes memory returnData) = swaper0x.delegatecall(
            abi.encodeWithSignature('fillQuote(address,address,address,address,bytes)',
                _USDCBNT_0x_quote.sellTokenAddress,
                _USDCBNT_0x_quote.buyTokenAddress,
                _USDCBNT_0x_quote.spender,
                _USDCBNT_0x_quote.swapTarget,
                _USDCBNT_0x_quote.swapCallData 
            )
        );
        require(success, 'USDCBNT 0x swap failed');
        if (!success) {
            console.log(Helpers._getRevertMsg(returnData));
        }
        console.log('4.- BNT balance (swap 0x): ', MyIERC20(_adr('BNT')).balanceOf(address(this)) / 1 ether);


        //BANCOR 
        //(USDC to BNT swap)
        MyIERC20[] memory path;
        uint minReturn; 
        uint amount;
        path = IBancorNetwork(_adr('bancorNetwork')).conversionPath(MyIERC20(_adr('USDC')), MyIERC20(_adr('BNT')));
        amount = 883608 * 10 ** 6; 
        minReturn = IBancorNetwork(_adr('bancorNetwork')).rateByPath(path, amount);
        MyIERC20(_adr('USDC')).approve(_adr('bancorNetwork'), type(uint).max);

        uint bntTraded = IBancorNetwork(_adr('bancorNetwork')).convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('5.- Amount of BNT traded (swap Bancor)', bntTraded / 1 ether);
        console.log('___5.1.- BNT balance (after Bancor swap): ', MyIERC20(_adr('BNT')).balanceOf(address(this)) / 1 ether);

        //(BNT to ETH swap)
        path = IBancorNetwork(_adr('bancorNetwork')).conversionPath(MyIERC20(_adr('BNT')), MyIERC20(_adr('ETH_Bancor')));
        amount = MyIERC20(_adr('BNT')).balanceOf(address(this));
        minReturn = IBancorNetwork(_adr('bancorNetwork')).rateByPath(path, amount);
        MyIERC20(_adr('BNT')).approve(_adr('bancorNetwork'), type(uint).max);

        IBancorNetwork(_adr('bancorNetwork')).convertByPath(path, amount, minReturn, address(this), address(0x0), 0);
        console.log('6.- ETH balance (2nd Bancor swap): ', address(this).balance / 1 ether); 

        //CURVE
        MyIERC20(_adr('USDC')).approve(_adr('yPool'), type(uint).max);
        amount = 894793 * 10 ** 6;
        ICurve(_adr('yPool')).exchange_underlying(1, 3, amount, 1);
        console.log('7.- TUSD balance (Curve swap): ', MyIERC20(_adr('TUSD')).balanceOf(address(this)) / 1 ether);

        // //SUSHISWAP 
        MyIERC20(_adr('TUSD')).approve(_adr('sushiRouter'), type(uint).max);
        amount = 11173 * 1 ether;
        address[] memory _path;
        _path = Helpers._createPath(_adr('TUSD'), _adr('WETH'));
        uint[] memory _amount;
        _amount = IUniswapV2Router02(_adr('sushiRouter')).swapExactTokensForETH(amount, 0, _path, payable(address(this)), block.timestamp);
        console.log('8.- ETH traded (Sushiswap swap): ', _amount[1] / 1 ether, '--', _amount[1]);

        // //0x
        // //(TUSD to WETH)
        (bool _success, bytes memory data) = revengeOfTheFlash.delegatecall(
            abi.encodeWithSignature('executeCont((address,address,address,address,bytes))',
             _TUSDWETH_0x_quote
            )
        );
        if (!_success) {
            console.log(Helpers._getRevertMsg(data));
        }
        require(_success, 'Delegatecall to Revenge of The Flash failed');

    }
    


}






