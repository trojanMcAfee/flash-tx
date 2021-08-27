const { legos } = require("@studydefi/money-legos");
// const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");
const { generatePseudoRandomSalt, Order, signatureUtils } = require('@0x/order-utils');
require('dotenv').config();



const { createQueryString, API_QUOTE_URL, getQuote, getQuote2 } = require('./relayer.js');
const { beginManagement, getHealthFactor, getUserReserveData_aave } = require('./health-factor.js');
const { showsCallersData, getUserAccountData_aave } = require('./callers-post-flash.js');
const { parseEther, parseUnits, formatEther, defaultAbiCoder } = ethers.utils;
const { MaxUint256 } = ethers.constants;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
const wbtcAdr = '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599';
const bntAddr = '0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C';
const offchainRelayer = '0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9';
const aUSDCAddr = '0xBcca60bB61934080951369a648Fb03DF4F96263C';
const aWethAddr = '0x030bA81f1c18d280636F32af80b9AAd02Cf0854e';
const callerContract = '0x278261c4545d65a81ec449945e83a236666B64F5';
const lendingPoolAaveAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
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


// async function getUserAccountData_aave(user) {
//   // const lendingPoolAaveAddr = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
//   const ILendingPool = await hre.ethers.getContractAt('MyILendingPool', '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9');
//   const tx = await ILendingPool.getUserAccountData(user);
//   console.log('********: ', tx);

// }






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
}




  const usdcData_caller = await getUserReserveData_aave(usdcAddr, callerContract, 10 ** 6);
  const usdtData_caller = await getUserReserveData_aave(usdtAddr, callerContract, 10 ** 6);
  const wethData_caller = await getUserReserveData_aave(wethAddr, callerContract, 10 ** 18);
  


  console.log('--------------------------- My deployed contracts ---------------------------');
  console.log('.');
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployer address: ', signerAddr);


  //Deploy the Helpers library
  const Helpers = await hre.ethers.getContractFactory('Helpers');
  const helpers = await Helpers.deploy();
  await helpers.deployed();
  console.log('Helpers deployed to: ', helpers.address);

  //Deploys the Swaper0x contract
  const Swaper0x = await hre.ethers.getContractFactory('Swaper0x', {
    libraries: {
      Helpers: helpers.address
    }
  });
  const swaper0x = await Swaper0x.deploy();
  await swaper0x.deployed();
  console.log('Swaper0x deployed to: ', swaper0x.address);
  
  //Deploys the 2nd part of the logic contract first
  // const RevengeOfTheFlash = await hre.ethers.getContractFactory('RevengeOfTheFlash');
  const RevengeOfTheFlash = await hre.ethers.getContractFactory('RevengeOfTheFlash', {
    libraries: {
      Helpers: helpers.address
    }
  });
  const revengeOfTheFlash = await RevengeOfTheFlash.deploy();
  await revengeOfTheFlash.deployed();
  console.log('Revenge Of The Flash deployed to: ', revengeOfTheFlash.address);

  //Deploys the logic contract (and links the Helpers library to it)
  // const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner', {
  //   libraries: {
  //     Helpers: helpers.address
  //   }
  // });
  const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner');
  const flashlogic = await FlashLoaner.deploy(swaper0x.address, revengeOfTheFlash.address, offchainRelayer);
  await flashlogic.deployed();
  await flashlogic.setExchange(swaper0x.address);
  console.log('flashlogic deployed to: ', flashlogic.address);

  
  //Deploys the proxy where the loan is requested
  const DydxFlashloaner = await hre.ethers.getContractFactory("DydxFlashloaner");
  const dxdxFlashloaner = await DydxFlashloaner.deploy(flashlogic.address, borrowed);
  await dxdxFlashloaner.deployed();
  console.log("dYdX_flashloaner deployed to:", dxdxFlashloaner.address);
  console.log('.');




  console.log("--------------------------- Health Factor Management (AAVE's Lending Pool) ---------------------------");
  console.log('.');

  await beginManagement(signer, swaper0x, wethAddr, flashlogic, usdcData_caller, usdtData_caller, wethData_caller);  

  console.log('.');
  console.log('---------------------------------- Swaps ----------------------------------');
  console.log('.');

  //Sends 2 gwei to the Proxy contract (dYdX flashloaner)
  
  value = parseUnits('2', "gwei"); //gwei
  await IWETH.deposit({ value });
  await IWETH.transfer(dxdxFlashloaner.address, value);

  
  /**** Sending 72 ETH while I solve the 0x problem ****/
  // value = parseUnits('73', "ether"); //gwei
  // await IWeth.deposit({ value });
  // await IWeth.transfer(flashlogic.address, value);


  //** impersonating..... */

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [offchainRelayer],
  });
  
  const signerImp = await ethers.getSigner(offchainRelayer);
  //1st swap (USDC to BNT - transfer BNT) //call approve from the swaper0x contract
  await IBNT.connect(signerImp).transfer(swaper0x.address, parseEther('1506.932141071984328329'));
  //2nd swap (TUSD to WETH - transfer WETH)
  await IWETH.connect(signerImp).transfer(swaper0x.address, parseEther('224.817255779374783216'));
  //3rd swap (USDC to WBTC - transfer WBTC)
  await IWBTC.connect(signerImp).transfer(swaper0x.address, 19.30930945 * 10 ** 8);
  //4th swap (WBTC to WETH - transfer WETH)
  await IWETH.connect(signerImp).transfer(swaper0x.address, parseEther('253.071556591057205072'));
  //5th swap (USDT to WETH - transfer WETH)
  await IWETH.connect(signerImp).transfer(swaper0x.address, parseEther('239.890714288415882321'));
  //6th swap (USDC to WETH - transfer WETH)
  await IWETH.connect(signerImp).transfer(swaper0x.address, parseEther('231.15052891491875094'));


  await hre.network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [offchainRelayer],
  });
//**** end of impersonating */


  

/*****  0x quotes *********/

  // const qs = createQueryString({
  //   sellToken: 'TUSD',
  //   buyToken: 'WETH',
  //   sellAmount: BigInt(882693 * 10 ** 18), //11184 * 10 ** 6
  //   // includedSources: 'Uniswap_V2'
  // }); 
  
  // const quoteUrl = `${API_QUOTE_URL}?${qs}&slippagePercentage=0.8`;
  // const response = await fetch(quoteUrl);
  // const quote = await response.json();


  // console.log('the quote: ', quote);
  // const quoteAddr = [
  //   quote.sellTokenAddress,
  //   quote.buyTokenAddress,
  //   quote.allowanceTarget, 
  //   quote.to
  // ];



/*****  0x quotes *********/


// let value2 = parseEther('1');
// await signer.sendTransaction({
//   value: value2,
//   to: flashlogic.address
// });



  const quotes_bytes_0x = [];
  const quotes_addr_0x = [];

  const USDCBNT_0x_quote = await getQuote('USDC', 'BNT', 11184 * 10 ** 6);
  quotes_addr_0x[0] = USDCBNT_0x_quote.addresses;
  quotes_bytes_0x[0] = USDCBNT_0x_quote.bytes; 


  const TUSDWETH_0x_quote = await getQuote('TUSD', 'WETH', BigInt(882693 * 10 ** 18)); 
  quotes_addr_0x[1] = TUSDWETH_0x_quote.addresses; 
  quotes_bytes_0x[1] = TUSDWETH_0x_quote.bytes; 
                                                
  
  const USDCWBTC_0x_quote = await getQuote('USDC', 'WBTC', 984272 * 10 ** 6);                                     
  quotes_addr_0x[2] = USDCWBTC_0x_quote.addresses;
  quotes_bytes_0x[2] = USDCWBTC_0x_quote.bytes;


  


  // await getUserReserveData_aave(usdcAddr, flashlogic.address, 'flashlogic', 10 ** 6);

  // await getUserReserveData_aave('0xdAC17F958D2ee523a2206206994597C13D831ec7', callerContract, 'caller', 10 ** 6);

  
  // const path = [wethAddr, usdcAddr];
  const IRouter = await hre.ethers.getContractAt('IUniswapV2Router02', uniswapRouterAddr);
  // await IRouter.swapExactETHForTokens(1, path, signerAddr, MaxUint256, {
  //   value: parseEther('376')
  // });
  // console.log('signer USDC balance: ', (await IUSDC.balanceOf(signerAddr)).toString() / 10 ** 6);


  // await IRouter.swapExactTokensForETH(1, path, signerAddr, MaxUint256, {
  //   value: parseEther('376')
  // });
  // console.log('signer USDC balance: ', (await IUSDC.balanceOf(signerAddr)).toString() / 10 ** 6);



  await dxdxFlashloaner.initiateFlashLoan(
    soloMarginAddr, 
    wethAddr, 
    borrowed,
    quotes_addr_0x,
    quotes_bytes_0x
  );


  console.log('.');
  console.log('---------------------------------- State of my contracts Post-Flash ----------------------------------');
  console.log('.');

  await showsCallersData(logsBalances, flashlogic.address, signerAddr, dxdxFlashloaner.address);


  await signer.sendTransaction({
    value: parseEther('0.1'),
    to: dxdxFlashloaner.address
  });


  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [dxdxFlashloaner.address],
  });
  const dydxSign = await ethers.getSigner(dxdxFlashloaner.address);

  const wethBalance = await IWETH.connect(dydxSign).balanceOf(dxdxFlashloaner.address);
  const path = [wethAddr, usdcAddr];
  const IWETH_erc20 = await hre.ethers.getContractAt('MyIERC20', wethAddr);
  await IWETH_erc20.connect(dydxSign).approve(uniswapRouterAddr, MaxUint256);
  await IRouter.connect(dydxSign).swapExactTokensForTokens(wethBalance, 1, path, signerAddr, MaxUint256);


  await hre.network.provider.request({
    method: "hardhat_stopImpersonatingAccount",
    params: [dxdxFlashloaner.address],
  });

  console.log('.');
  console.log('****** TOTAL PROFITS in USDC (signer address) ****** : ', (await IUSDC.balanceOf(signerAddr)).toString() / 10 ** 6);
  console.log('.');



  console.log('--------------------------- State of main origin contracts Post-Flash ---------------------------');
  console.log('.');

  //Resets the fork to the block before the flashloan
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

  await showsCallersData(logsBalances, org_callerContract, org_msgSender, org_dYdX_flashloaner, org_logicContract);



  








}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
