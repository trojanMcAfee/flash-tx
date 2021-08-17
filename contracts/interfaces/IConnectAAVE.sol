//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



interface IConnectAAVE {


    function deposit(address token, uint amt, uint getId, uint setId) external payable;
    function withdraw(address token, uint amt, uint getId, uint setId) external payable;

}

/**
Following the track on reverse. Right now on the deposit of the 4500 WETH.
Keep moving backwards.
Research how to withdraw a different asset from that of the deposit.
Keep moving forward since the beginning. Ask on Discord
Check the connectAAVE contract
 */