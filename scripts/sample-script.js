const { legos } = require("@studydefi/money-legos");
const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");
const quote  = require('./relayer');

const { createQueryString, API_QUOTE_URL } = require('./relayer.js');
const { parseEther, parseUnits, formatEther } = ethers.utils;
const { MaxUint256 } = ethers.constants;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; 
const linkAddr = '0x514910771af9ca656af840dff83e8264ecf986ca';
const uniswapRouterAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const borrowed = parseEther('6478');
let value;


async function main() {
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployers address: ', signerAddr);

  //Creates the Service Agreement that will be used by the Chainlink nodes to make the 0x API calls
  const PreCoordinator = await hre.ethers.getContractFactory('PreCoordinator');
  const precoordinator = await PreCoordinator.deploy();
  await precoordinator.deployed();
  const tx = await precoordinator.createServiceAgreement();
  const receipt = await tx.wait();
  console.log('Pre-Coordinator address: ', precoordinator.address);
  console.log('Service Agreement ID: ', receipt.logs[0].topics[1]);


  //Deploys the contract from where the API calls through Chainlink are requested
  const ChainlinkCall = await hre.ethers.getContractFactory('ChainlinkCall');
  const chainlinkcall = await ChainlinkCall.deploy(precoordinator.address, receipt.logs[0].topics[1]);
  await chainlinkcall.deployed();
  
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

  //Modified lendingPool AAVE
  // const AAVE = await hre.ethers.getContractFactory('LendingPool2')
  // const aave = await AAVE.deploy();
  // await aave.deployed();

  // console.log('this is paused: ', await aave.paused());

  value = parseEther('1');
  await signer.sendTransaction({
    to: dxdxFlashloaner.address,
    value
  });

  //Sends the LINK payment (5) to the contract that delegate-calls the oracles (from the service agreement)
  // value = parseEther('0.5');
  // const uniswapRouter = await hre.ethers.getContractAt(uniRouterABI, uniswapRouterAddr);
  // await uniswapRouter.swapETHForExactTokens(
  //   parseEther('6'), 
  //   [wethAddr, linkAddr], 
  //   flashlogic.address, 
  //   MaxUint256, {
  //     value 
  //   });

/*****  0x quotes *********/

  const sellAmount = 150 //parseUnits('150', 'gwei');
  const qs = createQueryString({
    sellToken: 'UNI',
    buyToken: 'BNT',
    sellAmount
  });
  
  const quoteUrl = `${API_QUOTE_URL}?${qs}`;
  const response = await fetch(quoteUrl);
  const quote = await response.json();

  // console.log('the quote: ', quote);
  const quoteAddr = [
    quote.sellTokenAddress,
    quote.buyTokenAddress,
    quote.allowanceTarget, //spender
    quote.to //swapTarget
    // quote.data //swapCallData
  ];

  console.log('sellAmount: ', (quote.sellAmount / 10 ** 18).toFixed(20));
  console.log('this is the quote: ', quote);
  console.log('value of the quote: ', quote.value);
  // console.log(formatEther(quote.buyAmount));

/*****  0x quotes *********/

   
  
// value = parseEther('1');
  await dxdxFlashloaner.initiateFlashLoan(
    soloMarginAddr, 
    wethAddr, 
    borrowed,
    quoteAddr,
    quote.data,
    quote.gas
  );





}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
