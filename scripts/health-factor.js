const { parseEther, formatEther, defaultAbiCoder } = ethers.utils;
const { MaxUint256 } = ethers.constants;

const aaveDataProviderAddr = '0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d';
const callerContract = '0x278261c4545d65a81ec449945e83a236666B64F5';
const lendingPoolAaveAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
const usdcAddr = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const uniswapRouterAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const WETHgatewayAddr = '0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04';
const aUSDCAddr = '0xBcca60bB61934080951369a648Fb03DF4F96263C';
const burnerAddr = '0x000000000000000000000000000000000000dEaD';
const usdtAddr = '0xdAC17F958D2ee523a2206206994597C13D831ec7';


async function getHealthFactor(user, swaper0x) {
    const tx = await swaper0x.getUserHealthFactor_aave(user);
    const receipt = await tx.wait();
    const { data } = receipt.logs[0];
    const decodedData = defaultAbiCoder.decode(["uint256"], data);
    return formatEther(decodedData.toString());
}



async function getUserData(asset, user, decimals) {
    const aaveDataProviderAddr = '0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d';
    const aaveDataProvider = await hre.ethers.getContractAt('IAaveProtocolDataProvider', aaveDataProviderAddr);
    const result =  await aaveDataProvider.getUserReserveData(asset, user);

    return {
      aBalance: result[0].toString() / decimals,
      currentVariableDebt: result[2].toString() / decimals,
      scaledVariableDebt: result[4].toString() / decimals
    }
        
        // console.log('*** ' + stringUser + ' ***');
        // console.log('aUSDC balance: ', result[0].toString() / decimals);
        // console.log('current variable debt: ', result[2].toString() / decimals);
        // console.log('scaledVariableDebt: ', result[4].toString() / decimals);
        // console.log('liquidityRate: ', result[6].toString());
        // console.log('usageAsCollateralEnabled:', result[8].toString());

}







async function beginManagement(signer, swaper0x, wethAddr, flashlogic, usdcData_caller, usdtData_caller, wethData_caller) {

    const aaveDataProvider = await hre.ethers.getContractAt('IAaveProtocolDataProvider', aaveDataProviderAddr);
    // const uniswapRouter = await hre.ethers.getContractAt('IUniswapV2Router02', uniswapRouterAddr);
    const IWETHgateway = await hre.ethers.getContractAt('IWETHgateway', WETHgatewayAddr);
    const lendingPoolAave = await hre.ethers.getContractAt('MyILendingPool', lendingPoolAaveAddr);
    const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
    const IUSDT = await hre.ethers.getContractAt('MyIERC20', usdtAddr);
    // const IaUSDC = await hre.ethers.getContractAt('MyIERC20', aUSDCAddr);

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
    
    const callerHealthFactor_preDeposit = await getHealthFactor(callerContract, swaper0x);
    // console.log("Caller's health factor pre-ETH deposit (forbids USDC withdrawal): ", callerHealthFactor_preDeposit);
  
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
    // console.log('ETH deposited by Caller in lending pool: ', formatEther(value));
    
    //Trades USDC for the borrowed amount made by the caller which will simulate the first supply of ETH to Aave's lending pool
    // const path = [wethAddr, usdcAddr];
    // await uniswapRouter.swapETHForExactTokens(callerBorrowedUSDC, path, flashlogic.address, MaxUint256, {
    //   value: parseEther('5100')
    // });

  
    //Starts impersonating the original caller for ETH deposit to increase Health Factor and allow USDC withdrawal
    await hre.network.provider.request({  
      method: "hardhat_impersonateAccount",
      params: [callerContract],
    });
    const callerSign = await ethers.getSigner(callerContract);
  
    //Deposit ETH in lending pool to increase health factor (caller)
    await IWETHgateway.connect(callerSign).depositETH(lendingPoolAaveAddr, callerContract, 0, { value });
    const callerHealthFactor_postDeposit = await getHealthFactor(callerContract, swaper0x);
    // console.log("Caller's health factor after ETH deposit (allows USDC withdrawal): ", callerHealthFactor_postDeposit);
  
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

    // console.log('**********************');
    // await lendingPoolAave.connect(flashlogicSign).withdraw(wethAddr, parseEther('10'), flashlogic.address);
    // await swaper0x.getUserData_aave(flashlogic.address);
    // console.log('**********************');
    
    //Stops impersonating Flashlogic
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [flashlogic.address],
    });
  
   
    //Gets Flashlogic's debt values and healthfactor
    tx = await aaveDataProvider.getUserReserveData(usdcAddr, flashlogic.address);
    flashlogicBorrowedUSDC = tx[2].toString();
    flashlogicATokenBalance_usdc = tx[0].toString();
    
    const flashlogicHealthFactor = await getHealthFactor(flashlogic.address, swaper0x);

    //Logs debt and health factor values
    // console.log('USDC debt of original Caller Contract with lending pool: ', callerBorrowedUSDC);
    // console.log('aUSDC balance of original Caller Contract: ', callerAtokenBalance_usdc);
    // console.log('USDC debt of Flashlogic with lending pool: ', flashlogicBorrowedUSDC);
    // console.log('aUSDC balance of Flashlogic: ', flashlogicATokenBalance_usdc);
    // console.log("Flashlogic's health factor after movements (forbids USDC withdrawals): ", flashlogicHealthFactor);

    // console.log('.');

    console.log("** Caller's USDC/USDT debt state (before flashloan) **");
    console.log('aUSDC balance: ', usdcData_caller.aBalance);
    console.log('Current Variable Debt: ', usdcData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt: ', usdcData_caller.scaledVariableDebt);
    // console.log(".");
    console.log('aUSDT balance: ', usdtData_caller.aBalance);
    console.log('Current Variable Debt: ', usdtData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt: ', usdtData_caller.scaledVariableDebt);

    console.log("Caller's health factor pre-ETH deposit (forbids USDC withdrawal): ", Number(callerHealthFactor_preDeposit));

    console.log('.');

    const usdcData_flashlogic = await getUserData(usdcAddr, flashlogic.address, 10 ** 6);
    const usdtData_flashlogic = await getUserData(usdtAddr, flashlogic.address, 10 ** 6);

    console.log("** Flashlogic's USDC/USDT debt state (after management and before flashloan) **");
    console.log('aUSDC balance: ', usdcData_flashlogic.aBalance);
    console.log('Current Variable Debt (usdc): ', usdcData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt (usdc): ', usdcData_flashlogic.scaledVariableDebt);
    // console.log(".");
    console.log('aUSDT balance: ', usdtData_flashlogic.aBalance);
    console.log('Current Variable Debt (usdt): ', usdtData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt (usdt): ', usdtData_flashlogic.scaledVariableDebt);

    console.log("Flashlogic's health factor after movements (forbids USDC withdrawals): ", Number(flashlogicHealthFactor));

    console.log('--------------');
    console.log('WETH data state caller:');
    console.log('aWETH balance: ', wethData_caller.aBalance);
    console.log('Current Variable Debt: ', wethData_caller.currentVariableDebt);
    console.log('Scaled Variable Debt: ', wethData_caller.scaledVariableDebt);
    
    console.log('.');

    const wethData_flashlogic = await getUserData(wethAddr, flashlogic.address, 10 ** 18);
    console.log('WETH data state flashlogic:');
    console.log('aWETH balance: ', wethData_flashlogic.aBalance);
    console.log('Current Variable Debt: ', wethData_flashlogic.currentVariableDebt);
    console.log('Scaled Variable Debt: ', wethData_flashlogic.scaledVariableDebt);


    

}


module.exports = {
    beginManagement,
    getHealthFactor,
    getUserData
}