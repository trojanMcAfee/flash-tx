const { legos } = require("@studydefi/money-legos");
// const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");

const { createQueryString, API_QUOTE_URL } = require('./relayer.js');
const { parseEther, parseUnits, formatEther } = ethers.utils;
// const { MaxUint256 } = ethers.constants;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
// const uniswapRouterAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const borrowed = parseEther('6478');
let value;


async function main() {
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
  value = parseUnits('2', "gwei"); 
  await IWeth.deposit({ value });
  await IWeth.transfer(dxdxFlashloaner.address, value);



/*****  0x quotes *********/

  const sellAmount = 11184; //parseUnits('150', 'gwei');
  const qs = createQueryString({
    sellToken: 'USDC',
    buyToken: 'BNT',
    sellAmount
  }); 
  
  const quoteUrl = `${API_QUOTE_URL}?${qs}&slippagePercentage=0.5`;
  const response = await fetch(quoteUrl);
  const quote = await response.json();

  // console.log('the quote: ', quote);
  const quoteAddr = [
    quote.sellTokenAddress,
    quote.buyTokenAddress,
    quote.allowanceTarget, 
    quote.to 
  ];


/*****  0x quotes *********/




   
  await dxdxFlashloaner.initiateFlashLoan(
    soloMarginAddr, 
    wethAddr, 
    borrowed,
    quoteAddr,
    quote.data
  );


}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
