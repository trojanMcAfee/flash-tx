const { legos } = require("@studydefi/money-legos");
// const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");
const { generatePseudoRandomSalt, Order, signatureUtils } = require('@0x/order-utils');



const { createQueryString, API_QUOTE_URL, getQuote, getQuote2 } = require('./relayer.js');
const { beginManagement, getHealthFactor, getUserData } = require('./health-factor.js');
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
const borrowed = parseEther('6478.183133980298798568');
let value;






async function main() {

  const usdcData_caller = await getUserData(usdcAddr, callerContract, 10 ** 6);
  const usdtData_caller = await getUserData(usdtAddr, callerContract, 10 ** 6);
  const wethData_caller = await getUserData(wethAddr, callerContract, 10 ** 18);
  


  console.log('--------------------------- Deployed contracts ---------------------------');
  console.log('.');
  const provider = hre.ethers.provider;
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployers address: ', signerAddr);


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
  const IWETH = await hre.ethers.getContractAt('IWETH', wethAddr);
  value = parseUnits('2', "gwei"); //gwei
  await IWETH.deposit({ value });
  await IWETH.transfer(dxdxFlashloaner.address, value);

  
  /**** Sending 72 ETH while I solve the 0x problem ****/
  // value = parseUnits('73', "ether"); //gwei
  // await IWeth.deposit({ value });
  // await IWeth.transfer(flashlogic.address, value);


  //** impersonating..... */
  const IBNT = await hre.ethers.getContractAt('MyIERC20', bntAddr);
  const IWBTC = await hre.ethers.getContractAt('MyIERC20', wbtcAdr);

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


  


  // await getUserData(usdcAddr, flashlogic.address, 'flashlogic', 10 ** 6);

  // await getUserData('0xdAC17F958D2ee523a2206206994597C13D831ec7', callerContract, 'caller', 10 ** 6);

  const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
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
  console.log('---------------------------------- Profits ----------------------------------');
  console.log('.');

  console.log('Before conversion: ');

  const wethBalance_dydxFlashloaner = formatEther(await IWETH.balanceOf(dxdxFlashloaner.address));
  console.log('WETH balance dydx flashloaner: ', wethBalance_dydxFlashloaner);

  const wethBalance_flashlogic = formatEther(await IWETH.balanceOf(flashlogic.address));
  console.log('WETH balance Flashlogic: ', wethBalance_flashlogic);

  const hf = await getHealthFactor(flashlogic.address, swaper0x);
  console.log('flashlogic health factor: ', hf);

  const IaUSDC = await hre.ethers.getContractAt('MyIERC20', aUSDCAddr);
  console.log('flashlogic aUSDC balance: ', Number((await IaUSDC.balanceOf(flashlogic.address)).toString()) / 10 ** 6);

  const IaWETH = await hre.ethers.getContractAt('MyIERC20', aWethAddr);
  console.log('flashlogic aWETH balance: ', formatEther(await IaWETH.balanceOf(flashlogic.address)));

  // const IUSDC = await hre.ethers.getContractAt('MyIERC20', usdcAddr);
  console.log('flashlogic USDC balance: ', (await IUSDC.balanceOf(flashlogic.address)).toString() / 10 ** 6);


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

  console.log('TOTAL PROFITS - USDC balance signer address: ', (await IUSDC.balanceOf(signerAddr)).toString() / 10 ** 6);


  await swaper0x.getUserData_aave(flashlogic.address);


  








}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
