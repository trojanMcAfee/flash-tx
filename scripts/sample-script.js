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


async function main() {
  const provider = hre.ethers.provider;
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployers address: ', signerAddr);

  
  //Deploys the logic contract
  const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner');
  const flashlogic = await FlashLoaner.deploy();
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
  quotes_bytes_0x[0] = USDCBNT_0x_quote.bytes; //problem: with one order, it works but wrong amount. With two orders (what i need), it reverts


  const TUSDWETH_0x_quote = await getQuote('TUSD', 'WETH', BigInt(882693 * 10 ** 18)); //when using 882693 works but wrong amount
  quotes_addr_0x[1] = TUSDWETH_0x_quote.addresses; //882693 * 10 ** 18 throws error on  quote
  quotes_bytes_0x[1] = TUSDWETH_0x_quote.bytes; //BigInt(882693 * 10 ** 18) gives quote but reverts on swap...works with BigInt(882693 * 10 ** 12) but wrong amount
                                                //if i include a source, quotes give one order and it works...it doesn't work with two orders (what I need)
  
  const USDCWBTC_0x_quote = await getQuote2('USDC', 'WBTC', 984272 * 10 ** 6);                                     
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
