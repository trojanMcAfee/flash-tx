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

    for (let i = 0; i < str.length; i++) {
        if (str[i] === 'currentLiquidationThreshold' || str[i] === 'ltv') {
            console.log(str[i] + ': ' + tx[i]);
        } else {
            console.log(str[i] + ': ' + formatEther(tx[i]));
        }
    }
}



async function showsCallersData(logsBalances, callerContract, msgSender, dYdX_flashloaner, logicContract = false) {
    let callerStr = callerContract !== '0x278261c4545d65a81ec449945e83a236666B64F5' ? 'Flashlogic' : 'Caller contract';
    let signerStr = msgSender !== '0x4cb2b6dcb8da65f8421fed3d44e0828e07594a60' ? 'Signer' : 'msg.sender';

    console.log(`${callerStr}'s debt: `);
    await getUserAccountData_aave(callerContract);
    console.log('.');
    console.log(`Balances of ${callerStr}: `, callerContract);
    await logsBalances(callerContract);
    console.log('.');
    console.log(`Balances of ${signerStr}: `, msgSender);
    await logsBalances(msgSender);
    console.log('.');
    if (logicContract) {
        console.log('Balances of logic contract: ', logicContract);
        await logsBalances(logicContract);
        console.log('.');
    }
    console.log('Balances of dydx Flashloaner: ', dYdX_flashloaner);
    await logsBalances(dYdX_flashloaner);
}



module.exports = {
    showsCallersData,
    getUserAccountData_aave
};





 