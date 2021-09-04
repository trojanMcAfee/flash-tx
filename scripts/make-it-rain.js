require('dotenv').config();

const { createPool } = require('./exchange-pool.js');
const { beginManagement, getUserReserveData_aave } = require('./health-factor.js');
const { showsCallersData } = require('./callers-post-flash.js');

const { parseEther, parseUnits, formatEther } = ethers.utils;
const { MaxUint256 } = ethers.constants;

const soloMarginAddr = '0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e';
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
const wbtcAdr = '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599';
const bntAddr = '0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C';
const offchainRelayer = '0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9';
const aUSDCAddr = '0xBcca60bB61934080951369a648Fb03DF4F96263C';
const aWethAddr = '0x030bA81f1c18d280636F32af80b9AAd02Cf0854e';
const callerContract = '0x278261c4545d65a81ec449945e83a236666B64F5';
const usdcAddr = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const uniswapRouterAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const usdtAddr = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const aUsdtAddr = '0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811';
const tusdAddr = '0x0000000000085d4780B73119b644AE5ecd22b376';
const borrowed = parseEther('6478.183133980298798568');
let value;

const org_msgSender = '0x4cb2b6dcb8da65f8421fed3d44e0828e07594a60';
const org_callerContract = '0x278261c4545d65a81ec449945e83a236666B64F5';
const org_logicContract = '0xb3c9669a5706477a2b237d98edb9b57678926f04';
const org_dYdX_flashloaner = '0x691d4172331a11912c6d0e6d1a002e3d7ced6a66';




async function main() {

  const provider = hre.ethers.provider;
  const orgBalanceETH = await provider.getBalance(org_msgSender);


  //ERC20 interfaces
  const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
  const IaUSDC = await hre.ethers.getContractAt('MyIERC20', aUSDCAddr);
  const IUSDT = await hre.ethers.getContractAt('MyIERC20', usdtAddr);
  const IaUSDT = await hre.ethers.getContractAt('MyIERC20', aUsdtAddr);
  const IWETH = await hre.ethers.getContractAt('IWETH', wethAddr);
  const IaWETH = await hre.ethers.getContractAt('MyIERC20', aWethAddr);
  const IBNT = await hre.ethers.getContractAt('MyIERC20', bntAddr);
  const IWBTC = await hre.ethers.getContractAt('MyIERC20', wbtcAdr);
  const ITUSD = await hre.ethers.getContractAt('MyIERC20', tusdAddr);


  //Logs the balances from the ERC20 tokens that were transacted with
  async function logsBalances(user) {
    console.log('USDC balance: ', (await IUSDC.balanceOf(user)).toString() / 10 ** 6);
    console.log('aUSDC balance: ', (await IaUSDC.balanceOf(user)).toString() / 10 ** 6);
    console.log('USDT balance: ', (await IUSDT.balanceOf(user)).toString() / 10 ** 6);
    console.log('aUSDT balance: ', (await IaUSDT.balanceOf(user)).toString() / 10 ** 6);
    console.log('ETH balance: ', Number(formatEther(await hre.ethers.provider.getBalance(user))));
    console.log('WETH balance: ', (await IWETH.balanceOf(user)).toString() / 10 ** 18);
    console.log('aWETH balance: ', (await IaWETH.balanceOf(user)).toString() / 10 ** 18);
    console.log('WBTC balance: ', (await IWBTC.balanceOf(user)).toString() / 10 ** 8);
    console.log('TUSD balance: ', (await ITUSD.balanceOf(user)).toString() / 10 ** 18);
    console.log('BNT balance: ', (await IBNT.balanceOf(user)).toString() / 10 ** 18);

    return Number(formatEther(await hre.ethers.provider.getBalance(user)));
  }

  //Gets the original Caller's reserve data from Aave's liquidity pool
  const usdcData_caller = await getUserReserveData_aave(usdcAddr, callerContract, 10 ** 6);
  const usdtData_caller = await getUserReserveData_aave(usdtAddr, callerContract, 10 ** 6);
  const wethData_caller = await getUserReserveData_aave(wethAddr, callerContract, 10 ** 18);
  


  console.log('---------------------------------------- My deployed contracts ----------------------------------------');
  console.log('.');
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployer address: ', signerAddr);


  //Deploys the Exchange contract
  const Exchange = await hre.ethers.getContractFactory('Exchange');
  const exchange = await Exchange.deploy();
  await exchange.deployed();
  console.log('Exchange deployed to: ', exchange.address);
  
  //Deploys the 2nd part of the logic contracts first
  const RevengeOfTheFlash = await hre.ethers.getContractFactory('RevengeOfTheFlash');
  const revengeOfTheFlash = await RevengeOfTheFlash.deploy();
  await revengeOfTheFlash.deployed();
  console.log('Revenge Of The Flash deployed to: ', revengeOfTheFlash.address);

  //Deploys the first logic contract
  const Flashloaner = await hre.ethers.getContractFactory('Flashloaner');
  const flashlogic = await Flashloaner.deploy(exchange.address, revengeOfTheFlash.address, offchainRelayer);
  await flashlogic.deployed();
  await flashlogic.setExchange(exchange.address);
  console.log('flashlogic deployed to: ', flashlogic.address);

  //Deploys the proxy where the loan is requested
  const DydxFlashloaner = await hre.ethers.getContractFactory('DyDxFlashloaner');
  const dxdxFlashloaner = await DydxFlashloaner.deploy(flashlogic.address, borrowed);
  await dxdxFlashloaner.deployed();
  console.log("dYdX_flashloaner deployed to:", dxdxFlashloaner.address);
  await flashlogic.setDydxFlashloanerSecondOwner(dxdxFlashloaner.address);
  console.log('.');

  await exchange.setFlashloanerSecondOwner(flashlogic.address);


  console.log("--------------------------- Health Factor Management (AAVE's Lending Pool) ---------------------------");
  console.log('.');

  const callerHealthFactor_preDeposit = await beginManagement(signer, exchange, wethAddr, flashlogic, usdcData_caller, usdtData_caller, wethData_caller);  

  console.log('.');
  console.log('--------------------------------------------- Swaps ----------------------------------------------');
  console.log('.');

  //Sends 2 gwei to the Proxy contract (dYdX flashloaner)
  value = parseUnits('2', "gwei"); //gwei
  await IWETH.deposit({ value });
  await IWETH.transfer(dxdxFlashloaner.address, value);

  //Initiates the transfers from the offchain 0x relayer to the Exchange contract
  await createPool(offchainRelayer, exchange, IBNT, IWETH, IWBTC);


  //Initiates flashloan and transaction (MAIN CALL)
  const tx = await dxdxFlashloaner.initiateFlashLoan(
    soloMarginAddr, 
    wethAddr, 
    borrowed
  );
  

  console.log('.');
  console.log('---------------------------------- State of my contracts Post-Flash ----------------------------------');
  console.log('.');

  //Logs the balances of Flashlogic
  await showsCallersData(logsBalances, flashlogic.address, signerAddr, dxdxFlashloaner.address);

  //For paying for the fees of the WETH/USDC trade to calculate the gross profits in USDC
  await signer.sendTransaction({
    value: parseEther('0.1'),
    to: dxdxFlashloaner.address
  });


  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [dxdxFlashloaner.address],
  });
  const dydxSign = await ethers.getSigner(dxdxFlashloaner.address);

  //Calculates gross profits in USDC
  const wethBalance = await IWETH.connect(dydxSign).balanceOf(dxdxFlashloaner.address);
  const path = [wethAddr, usdcAddr];
  const IWETH_erc20 = await hre.ethers.getContractAt('MyIERC20', wethAddr);
  await IWETH_erc20.connect(dydxSign).approve(uniswapRouterAddr, MaxUint256);

  const IUniRouter = await hre.ethers.getContractAt('IUniswapV2Router02', uniswapRouterAddr);
  await IUniRouter.connect(dydxSign).swapExactTokensForTokens(wethBalance, 1, path, signerAddr, MaxUint256);


  await hre.network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [dxdxFlashloaner.address],
  });

  console.log('.');
  console.log('****** TOTAL GROSS PROFITS in USDC (signer) ****** : ', (await IUSDC.balanceOf(signerAddr)).toString() / 10 ** 6);
  console.log('.');

  //Calculates the gas fees of my contracts 
  const gasPrice = (await tx.gasPrice).toString();
  const gasUsed = ((await tx.wait()).gasUsed).toString();
  console.log('Gas price: ', Number(gasPrice));
  console.log('Gas used: ', Number(gasUsed));
  console.log('TOTAL GAS fees (in ETH): ',  (gasPrice * gasUsed) / 10 ** 18);


  console.log('.');
  console.log('--------------------------- State of main origin contracts Post-Flash ---------------------------');
  console.log('.');

  //Resets the fork to the block after the flashloan (for the calculation of the state of the original caller post-flash)
  await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: process.env.ALCHEMY_URL,
          blockNumber: 12431520,
        },
      },
    ],
  });

  console.log('ETH balance of original msg.sender (pre-flashloan): ', formatEther(orgBalanceETH));
  console.log('.');

  //Logs the balances of the original contract
  const debtDataMsgSender = await showsCallersData(logsBalances, org_callerContract, org_msgSender, org_dYdX_flashloaner, org_logicContract);
  console.log('.');
  console.log('****** TOTAL NET PROFITS in ETH (original signer) after GAS fees ****** : ', debtDataMsgSender.ETHbalanceMsgSender - formatEther(orgBalanceETH));
  console.log('****** Marginal variance HEALTH FACTOR ****** : ', debtDataMsgSender.healthFactor - callerHealthFactor_preDeposit);
  console.log('.');

}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
