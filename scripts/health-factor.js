const { parseEther, formatEther, defaultAbiCoder } = ethers.utils;

const aaveDataProviderAddr = '0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d';
const callerContract = '0x278261c4545d65a81ec449945e83a236666B64F5';
const lendingPoolAaveAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
const usdcAddr = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const WETHgatewayAddr = '0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04';
const burnerAddr = '0x000000000000000000000000000000000000dEaD';
const usdtAddr = '0xdAC17F958D2ee523a2206206994597C13D831ec7';


async function getHealthFactor(user, exchange) {
    const tx = await exchange.getUserHealthFactor_aave(user);
    const receipt = await tx.wait();
    const { data } = receipt.logs[0];
    const decodedData = defaultAbiCoder.decode(["uint256"], data);
    return formatEther(decodedData.toString());
}



async function getUserReserveData_aave(asset, user, decimals) {
    const aaveDataProviderAddr = '0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d';
    const aaveDataProvider = await hre.ethers.getContractAt('IAaveProtocolDataProvider', aaveDataProviderAddr);
    const result =  await aaveDataProvider.getUserReserveData(asset, user);

    return {
      aBalance: result[0].toString() / decimals,
      currentVariableDebt: result[2].toString() / decimals,
      scaledVariableDebt: result[4].toString() / decimals
    }
}





async function beginManagement(signer, exchange, wethAddr, flashlogic, usdcData_caller, usdtData_caller, wethData_caller) {

    const aaveDataProvider = await hre.ethers.getContractAt('IAaveProtocolDataProvider', aaveDataProviderAddr);
    const IWETHgateway = await hre.ethers.getContractAt('IWETHgateway', WETHgatewayAddr);
    const lendingPoolAave = await hre.ethers.getContractAt('MyILendingPool', lendingPoolAaveAddr);
    const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
    const IUSDT = await hre.ethers.getContractAt('MyIERC20', usdtAddr);

    const usdcToBorrow = 17895868 * 10 ** 6;
    const usdtCallerDebt = 785267.209694 * 10 ** 6;
    let callerBorrowedUSDC;
    let callerAtokenBalance_usdc;
    let flashlogicBorrowedUSDC;
    let flashlogicATokenBalance_usdc;
  
    //Gets the debt values from the original caller pre-management
    let tx = await aaveDataProvider.getUserReserveData(usdcAddr, callerContract);
    callerBorrowedUSDC = tx[2].toString();
    callerAtokenBalance_usdc = tx[0].toString();
    
    const callerHealthFactor_preDeposit = await getHealthFactor(callerContract, exchange);
  
    //Sends ETH to original Caller for paying the fees of withdrawing USDC from lending pool
    await signer.sendTransaction({
      value: parseEther('0.1'),
      to: callerContract
    }); 
  
    //Sends ETH to original caller which will be used to increase health factor so USDC withdrawal is possible
    let value = parseEther('4505.879348962757498457');
    await signer.sendTransaction({
      value,
      to: callerContract
    }); 
    

    //Starts impersonating the original caller for ETH deposit to increase Health Factor and allow USDC withdrawal
    await hre.network.provider.request({  
      method: "hardhat_impersonateAccount",
      params: [callerContract],
    });
    const callerSign = await ethers.getSigner(callerContract);
  
    //Deposit ETH in lending pool to increase health factor (caller)
    await IWETHgateway.connect(callerSign).depositETH(lendingPoolAaveAddr, callerContract, 0, { value });
  
    //Withdraw USDC from lending pool and send them to Flashlogic
    await lendingPoolAave.connect(callerSign).withdraw(usdcAddr, usdcToBorrow, flashlogic.address);
  
    //Stops impersonating the original caller
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [callerContract],
    });
  
    
    //Impersonates Flashlogic for making USDC deposit to lending pool
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [flashlogic.address],
    });
    const flashlogicSign = await ethers.getSigner(flashlogic.address);
    
    //Sends ETH for paying the fees for depositing into lending pool
    await signer.sendTransaction({
      value: parseEther('0.2'),
      to: flashlogic.address
    });
    
    //Deposits USDC to lending pool and borrows in order to match original caller's debt
    const totalUSDCdeposit = usdcToBorrow; //usdcToBorrow + Number(callerBorrowedUSDC);
    await IUSDC.connect(flashlogicSign).approve(lendingPoolAaveAddr, totalUSDCdeposit);
    await lendingPoolAave.connect(flashlogicSign).deposit(usdcAddr, totalUSDCdeposit, flashlogic.address, 0);
    await lendingPoolAave.connect(flashlogicSign).borrow(usdcAddr, Number(callerBorrowedUSDC), 2, 0, flashlogic.address);

    //Borrows USDT to finish matching with caller's health factor
    await lendingPoolAave.connect(flashlogicSign).borrow(usdtAddr, usdtCallerDebt, 2, 0, flashlogic.address);
  
    //Spends amount equally to original caller's debt (both in USDC and USDT) in order to match their health factor
    await IUSDC.connect(flashlogicSign).transfer(burnerAddr, Number(callerBorrowedUSDC));
    await IUSDT.connect(flashlogicSign).transfer(burnerAddr, usdtCallerDebt);
    
    //Stops impersonating Flashlogic
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [flashlogic.address],
    });
  
   
    //Gets Flashlogic's debt values and healthfactor
    tx = await aaveDataProvider.getUserReserveData(usdcAddr, flashlogic.address);
    flashlogicBorrowedUSDC = tx[2].toString();
    flashlogicATokenBalance_usdc = tx[0].toString();
    
    
    //Caller's USDC/USDT/WETH debt state (before flashloan)
    console.log("*** Caller's USDC/USDT/WETH debt state (before flashloan) ***");
    console.log('aUSDC balance: ', usdcData_caller.aBalance);
    console.log('Current Variable Debt (usdc): ', usdcData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt (usdc): ', usdcData_caller.scaledVariableDebt);
    
    console.log('aUSDT balance: ', usdtData_caller.aBalance);
    console.log('Current Variable Debt (usdt): ', usdtData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt (usdt): ', usdtData_caller.scaledVariableDebt);

    console.log('aWETH balance: ', wethData_caller.aBalance);
    console.log('Current Variable Debt (weth): ', wethData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt (weth): ', wethData_caller.scaledVariableDebt);

    console.log("Caller's health factor pre-ETH deposit (forbids USDC withdrawal): ", Number(callerHealthFactor_preDeposit));

    console.log('.');

    //Flashlogic's USDC/USDT/WETH debt state (after management and before flashloan)
    const usdcData_flashlogic = await getUserReserveData_aave(usdcAddr, flashlogic.address, 10 ** 6);
    const usdtData_flashlogic = await getUserReserveData_aave(usdtAddr, flashlogic.address, 10 ** 6);

    console.log("*** Flashlogic's USDC/USDT/WETH debt state (after management and before flashloan) ***");
    console.log('aUSDC balance: ', usdcData_flashlogic.aBalance);
    console.log('Current Variable Debt (usdc): ', usdcData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt (usdc): ', usdcData_flashlogic.scaledVariableDebt);
    
    console.log('aUSDT balance: ', usdtData_flashlogic.aBalance);
    console.log('Current Variable Debt (usdt): ', usdtData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt (usdt): ', usdtData_flashlogic.scaledVariableDebt);
    
    const wethData_flashlogic = await getUserReserveData_aave(wethAddr, flashlogic.address, 10 ** 18);
    console.log('aWETH balance: ', wethData_flashlogic.aBalance);
    console.log('Current Variable Debt (weth): ', wethData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt (weth): ', wethData_flashlogic.scaledVariableDebt);
    
    const flashlogicHealthFactor = await getHealthFactor(flashlogic.address, exchange);
    console.log("Flashlogic's health factor after movements (forbids USDC withdrawals): ", Number(flashlogicHealthFactor));

    return Number(callerHealthFactor_preDeposit);

}


module.exports = {
    beginManagement,
    getHealthFactor,
    getUserReserveData_aave
}