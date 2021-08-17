const { legos } = require("@studydefi/money-legos");
// const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");
const { generatePseudoRandomSalt, Order, signatureUtils } = require('@0x/order-utils');



const { createQueryString, API_QUOTE_URL, getQuote, getQuote2 } = require('./relayer.js');
const { parseEther, parseUnits, formatEther } = ethers.utils;
const { MaxUint256 } = ethers.constants;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
const wbtcAdr = '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599';
const bntAddr = '0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C';
const offchainRelayer = '0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9';
const borrowed = parseEther('6478.183133980298798568');
let value;





async function main() {
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
                                        
  await dxdxFlashloaner.initiateFlashLoan(
    soloMarginAddr, 
    wethAddr, 
    borrowed,
    quotes_addr_0x,
    quotes_bytes_0x
  );


  // await dxdxFlashloaner.initiateFlashLoan(
  //   soloMarginAddr, 
  //   wethAddr, 
  //   borrowed,
  //   quoteAddr,
  //   quote.data
  // );


}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
