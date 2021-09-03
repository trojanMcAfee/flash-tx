# Flashbots Arbitrage
This project is the recreation of a Flashbots arbitrage transaction made on May 14th, 2021 (pre-London). 

According to the MEV-explore dashboard, it initially had a profit of $2,156,968.55, but after re-doing the transaction, I came up with a different P/L which I back up with on-chain data, Flashbots documentation and a confirmation from their Discord server around the variance between numbers.


## Transaction
Etherscan: https://etherscan.io/tx/0x3ab816a20fc30ff563c1a3730150e9da3c513fb127d82cf1cdf3ac4d989e3643

Tenderly: https://dashboard.tenderly.co/tx/mainnet/0x3ab816a20fc30ff563c1a3730150e9da3c513fb127d82cf1cdf3ac4d989e3643

MEV-Explore Dashboard: 

![MEV-explore](./images/MEV-explore.png)

## Protocols involved
1. DyDx
2. Aave
3. 0x (in original tx)
4. Bancor
5. Curve
6. Sushiswap
7. Uniswap v2
8. Balancer
9. Dodo
10. CRO Protocol (Crypto.com)
11. 1Inch (in original tx)


## Structure of the project

![Structure](./images/Structure.png)

| Contract | Type | Description |
| ----- | ----- | -----|
| Flashloaner / flashlogic | Core | Main storage contract |
| RevengeOfTheFlash | Core | Continues the execution of the arbitrage from `Flashloaner` |
| DyDxFlashloaner | Periphery | Borrows WETH from `Solo (dydx)` contract (flashloan) and forwards funds to `Flashloaner` |  
| Exchange | Periphery | Swap functions from protocols and custom-made liquidity pool | 
| Helpers | Periphery | Holds main function that connects `Exchange` with `Core`, among other helper functions |
| make-it-rain | Node | Entry file to contracts through `DyDxFlashloaner` |
| exchange-pool | Node | Creates the `Exchange`'s liquidity pool | 
| health-factor | Node | Sets up `Flashloaner`'s health factor within Aave's liquidity pool to match original caller contract |
| callers-post-flash | Node | Logs the final state of both my contracts and original contracts |

`Flashloaner` is the main contract where the all the state variables are stored. For this reason, the majority of the connections that it makes to other contracts are through `DELEGATECALL` to preserve this centralization of storage for better efficiency. 

`RevengeOfTheFlash` continues the arbitrage from `Flasloaner`. 

`DyDxFlashloaner` is the contract that executes the flashloan from DyDx's `Solo` contract and borrows WETH. It later on forwards the funds and storage of the transaction to `Flashloaner` by a `CALL`.

`Exchange` is where all the functions that swap between protocols are located. It also stores the funds from the liquidity pool created by `exchange-pool`, and the function that withdraws them.

`Helpers` connects the `Core` contracts with the `Exchange` through its main function `swapToExchange` by `DELEGATECALL`:

```js
function swapToExchange(
    bytes memory _encodedData, 
    string memory _swapDesc, 
    address _exchange
) internal returns(uint tradedAmount) {

    (bool success, bytes memory returnData) = _exchange.delegatecall(_encodedData);
    if (success && returnData.length > 0) {
        (tradedAmount) = abi.decode(returnData, (uint256));
    } else if (!success) {
        console.log(Helpers._getRevertMsg(returnData), '--', _swapDesc, 'failed');
        revert();
    }
    
}
```

Contains as well other helpers functions, like for decoding the response bytes data in case of an error into a readable string. 

`make-it-rain` is the main entry file to the contracts. Deployments and the calculation of P/L happens here. 

`exchange-pool` creates the liquidity pool from where `Core` extracts funds replacing the 0x trades of the original transaction (more details below). 

`health-factor` matches the health factor and debt state of `Flashloaner` within Aave's main liquidity pool with that of the original caller (pre-flashloan), so `Flashloaner` enters in the exact same conditions to the transaction as that of the original caller.

`callers-post-flash` logs the state of my contracts post this transaction, and the original contract's post the original transaction.


## Explanation of `exchange-pool`

This file replaces six 0x swaps from the original transaction for a custom-made liquidity pool within the `Exchange` contract:

- `Swap 11,184.9175 USDC For 1,506.932141071984328329 BNT On 0x Protocol` (#4)
- `Swap 882,693.24684888583010072 TUSD For 224.817255779374783216 WETH On 0x Protocol` (#9)
- `Swap 984,272.740048 USDC For 19.30930945 WBTC On 0x Protocol` (#12)
- `Swap 19.66568451 WBTC For 253.071556591057205072 WETH On 0x Protocol` (#17)
- `Swap 938,699.561732 USDT For 239.890714288415882321 WETH On 0x Protocol` (#20)
- `Swap 905,978.317545 USDC For 231.15052891491875094 WETH On 0x Protocol` (#26)

The reason of this is because the original transaction uses an off-chain relayer for these trades which swaps are performed through the 0x SRA API v2. Due to the off-chain nature of these trades, a mainnet fork with an old pinned block cannot be deterministic since it can't access off-chain state from the past. 


## Pre-Flashloan state of my contracts







