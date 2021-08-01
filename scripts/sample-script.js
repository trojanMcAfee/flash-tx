const { legos } = require("@studydefi/money-legos");
// const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");


const { createQueryString, API_QUOTE_URL, getQuote, getQuote2 } = require('./relayer.js');
const { parseEther, parseUnits, formatEther } = ethers.utils;
// const { MaxUint256 } = ethers.constants;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
// const uniswapRouterAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const borrowed = parseEther('6478');
let value;

const addrNames = [
  'WBTC',
  'WETH',
  'USDC',
  'BNT',
  'TUSD',
  'lendingPoolAAVE',
  'ContractRegistry_Bancor',
  'ETH_Bancor',
  'yPool',
  'sushiRouter',
  'uniswapRouter',
  '1Inch',
];

const addresses = [
  '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599',
  '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
  '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  '0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C',
  '0x0000000000085d4780B73119b644AE5ecd22b376',
  '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9',
  '0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4',
  '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
  '0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51',
  '0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F',
  '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
  '0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e'
];


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
  const Swaper0x = await hre.ethers.getContractFactory('Swaper0x');
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
  console.log('Revenge-Of-The-Flash deployed to: ', revengeOfTheFlash.address);

  //Deploys the logic contract (and links the Helpers library to it)
  const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner', {
    libraries: {
      Helpers: helpers.address
    }
  });
  const flashlogic = await FlashLoaner.deploy(swaper0x.address, revengeOfTheFlash.address, addrNames, addresses);
  await flashlogic.deployed();
  console.log('flashlogic deployed to: ', flashlogic.address);

  
  //Deploys the proxy where the loan is requested
  const DydxFlashloaner = await hre.ethers.getContractFactory("DydxFlashloaner");
  const dxdxFlashloaner = await DydxFlashloaner.deploy(flashlogic.address, borrowed);
  await dxdxFlashloaner.deployed();
  console.log("dYdX_flashloaner deployed to:", dxdxFlashloaner.address);


  //Sends 2 gwei to the Proxy contract (dYdX flashloaner)
  const IWeth = await hre.ethers.getContractAt('IWETH', wethAddr);
  value = parseUnits('2', "gwei"); //gwei
  await IWeth.deposit({ value });
  await IWeth.transfer(dxdxFlashloaner.address, value);

  /**** Sending 72 ETH while I solve the 0x problem ****/
  value = parseUnits('73', "ether"); //gwei
  await IWeth.deposit({ value });
  await IWeth.transfer(flashlogic.address, value);

  

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
