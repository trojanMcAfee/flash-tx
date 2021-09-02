const { formatEther } = ethers.utils;


async function getUserAccountData_aave(user) {
    const ILendingPool = await hre.ethers.getContractAt('MyILendingPool', '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9');
    const tx = await ILendingPool.getUserAccountData(user);
    const str = [
        'totalCollateralETH',
        'totalDebtETH',
        'availableBorrowsETH',
        'currentLiquidationThreshold',
        'ltv',
        'healthFactor'
    ];
    let healthFactor;

    for (let i = 0; i < str.length; i++) {
        let debtProp = str[i];
        let txProp = tx[i];
        if (debtProp === 'currentLiquidationThreshold' || debtProp === 'ltv') {
            console.log(debtProp + ': ' + txProp);
        } else {
            console.log(debtProp + ': ' + formatEther(txProp));
            if (debtProp === 'healthFactor') healthFactor = formatEther(txProp);
        }
    }

    return healthFactor;
}



async function showsCallersData(logsBalances, callerContract, msgSender, dYdX_flashloaner, logicContract = false) {
    let callerStr = callerContract !== '0x278261c4545d65a81ec449945e83a236666B64F5' ? 'Flashlogic' : 'Caller contract';
    let signerStr = msgSender !== '0x4cb2b6dcb8da65f8421fed3d44e0828e07594a60' ? 'Signer' : 'msg.sender';

    console.log(`${callerStr}'s debt: `);
    const healthFactor = await getUserAccountData_aave(callerContract);
    console.log('.');
    console.log(`Balances of ${callerStr}: `, callerContract);
    await logsBalances(callerContract);
    console.log('.');
    console.log(`Balances of ${signerStr}: `, msgSender);
    const ETHbalanceMsgSender = await logsBalances(msgSender); 
    console.log('.');
    if (logicContract) {
        console.log('Balances of logic contract: ', logicContract);
        await logsBalances(logicContract);
        console.log('.');
    }
    console.log('Balances of dydx Flashloaner: ', dYdX_flashloaner);
    await logsBalances(dYdX_flashloaner);

    return {
        ETHbalanceMsgSender,
        healthFactor
    };
}



module.exports = {
    showsCallersData,
    getUserAccountData_aave
};





 