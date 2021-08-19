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


async function getHealthFactor(_receipt) {
    const { data } = _receipt.logs[0];
    const decodedData = defaultAbiCoder.decode(["uint256"], data);
    return formatEther(decodedData.toString());
}



async function beginManagement(signer, swaper0x, wethAddr, flashlogic) {

    const aaveDataProvider = await hre.ethers.getContractAt('IAaveProtocolDataProvider', aaveDataProviderAddr);
    const uniswapRouter = await hre.ethers.getContractAt('IUniswapV2Router02', uniswapRouterAddr);
    const IWETHgateway = await hre.ethers.getContractAt('IWETHgateway', WETHgatewayAddr);
    const lendingPoolAave = await hre.ethers.getContractAt('MyILendingPool', lendingPoolAaveAddr);
    const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
    const IaUSDC = await hre.ethers.getContractAt('MyIERC20', aUSDCAddr);

    const usdcToBorrow = 17895868 * 10 ** 6;
    let callerBorrowedUSDC;
    let callerAtokenBalance_usdc;
    let flashlogicBorrowedUSDC;
    let flashlogicATokenBalance_usdc;
  
    //Gets the debt values from the original caller pre-management
    let tx = await aaveDataProvider.getUserReserveData(usdcAddr, callerContract);
    callerBorrowedUSDC = tx[2].toString();
    callerAtokenBalance_usdc = tx[0].toString();
    
    tx = await swaper0x.getUserHealthFactor_aave(callerContract);
    let receipt = await tx.wait();
    let healthFactor = await getHealthFactor(receipt);
    console.log("Caller's health factor pre-ETH deposit (forbids USDC withdrawal): ", healthFactor);
  
    //Sends ETH to original Caller for paying the fees of withdrawing USDC from lending pool
    await signer.sendTransaction({
      value: parseEther('0.1'),
      to: callerContract
    }); 
  
    //Sends ETH to original caller which will be used to increase healh factor
    let value = parseEther('4505.879348962757498457');
    await signer.sendTransaction({
      value,
      to: callerContract
    }); 
    console.log('ETH deposited by Caller in lending pool: ', formatEther(value));
    
    //Trades USDC for the borrowed amount made by the caller which will simulate the first supply of ETH to Aave's lending pool
    const path = [wethAddr, usdcAddr];
    await uniswapRouter.swapETHForExactTokens(callerBorrowedUSDC, path, flashlogic.address, MaxUint256, {
      value: parseEther('5100')
    });

  
    //Starts impersonating the original caller for ETH deposit to increase Health Factor and USDC withdrawal
    await hre.network.provider.request({  
      method: "hardhat_impersonateAccount",
      params: [callerContract],
    });
    const callerSign = await ethers.getSigner(callerContract);
  
    //Deposit ETH in lending pool to increase health factor (caller)
    await IWETHgateway.connect(callerSign).depositETH(lendingPoolAaveAddr, callerContract, 0, { value });
    tx = await swaper0x.getUserHealthFactor_aave(callerContract);
    receipt = await tx.wait();
    healthFactor = await getHealthFactor(receipt);
    console.log("Caller's health factor after ETH deposit (allows USDC withdrawal): ", healthFactor);
  
    //Withdraw USDC from lending pool and send them to Flashlogic
    await lendingPoolAave.connect(callerSign).withdraw(usdcAddr, usdcToBorrow, flashlogic.address);
  
    //Stops impersonating the original caller
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [callerContract],
    });
  
    
    //Impersonates Flashlogic for making the deposit to the lending pool
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [flashlogic.address],
    });
    const flashlogicSign = await ethers.getSigner(flashlogic.address);
    
    //Sends ETH for paying the fees for depositing into the lending pool
    await signer.sendTransaction({
      value: parseEther('0.1'),
      to: flashlogic.address
    });
    
    //Deposits USDC to lending pool and borrows in order to match original caller's debt
    const totalUSDCdeposit = usdcToBorrow + Number(callerBorrowedUSDC);
    await IUSDC.connect(flashlogicSign).approve(lendingPoolAaveAddr, totalUSDCdeposit);
    await lendingPoolAave.connect(flashlogicSign).deposit(usdcAddr, totalUSDCdeposit, flashlogic.address, 0);
    await lendingPoolAave.connect(flashlogicSign).borrow(usdcAddr, callerBorrowedUSDC, 2, 0, flashlogic.address);
  
    //Spends amount equally to original caller's debt in order to match their health factor
    await IaUSDC.connect(flashlogicSign).transfer(burnerAddr, Number(callerBorrowedUSDC));
  
    //Stops impersonating Flashlogic
    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [flashlogic.address],
    });
  
   
    //Gets Flashlogic's debt values and healthfactor
    tx = await aaveDataProvider.getUserReserveData(usdcAddr, flashlogic.address);
    flashlogicBorrowedUSDC = tx[2].toString();
    flashlogicATokenBalance_usdc = tx[0].toString();
    
    tx = await swaper0x.getUserHealthFactor_aave(flashlogic.address);
    receipt = await tx.wait();
    healthFactor = await getHealthFactor(receipt);

    //Logs debt and health factor values
    console.log('USDC debt of original Caller Contract with lending pool: ', callerBorrowedUSDC);
    console.log('aUSDC balance of original Caller Contract: ', callerAtokenBalance_usdc);
    console.log('USDC debt of Flashlogic with lending pool: ', flashlogicBorrowedUSDC);
    console.log('aUSDC balance of Flashlogic: ', flashlogicATokenBalance_usdc);
    console.log("Flashlogic's health factor after movements (forbids USDC withdrawals): ", healthFactor);
    //probably caller has other assets deposited in the lending pool

}


module.exports = {
    beginManagement
}