const { legos } = require("@studydefi/money-legos");
const uniRouterABI = require('../artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json').abi;
const fetch = require("node-fetch");
const { createQueryString, API_QUOTE_URL } = require('./relayer');


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
  
  //Deploys the proxy where the loan is requested
  const DydxFlashloaner = await hre.ethers.getContractFactory("DydxFlashloaner");
  const dxdxFlashloaner = await DydxFlashloaner.deploy(flashlogic.address, borrowed, chainlinkcall.address);
  await dxdxFlashloaner.deployed();
  console.log("dYdX_flashloaner deployed to:", dxdxFlashloaner.address);

  //Sends 2 gwei to the Proxy contract (dYdX flashloaner)
  const IWeth = await hre.ethers.getContractAt('IWETH', wethAddr);
  value = parseUnits('2', "gwei");
  await IWeth.deposit({ value });
  await IWeth.transfer(dxdxFlashloaner.address, value);

  //Sends the LINK payment (5) to the contract that delegate-calls the oracles (from the service agreement)
  value = parseEther('0.5');
  const uniswapRouter = await hre.ethers.getContractAt(uniRouterABI, uniswapRouterAddr);
  await uniswapRouter.swapETHForExactTokens(
    parseEther('6'), 
    [wethAddr, linkAddr], 
    flashlogic.address, 
    MaxUint256, {
      value 
    });




  

   
  
  await dxdxFlashloaner.initiateFlashLoan(soloMarginAddr, wethAddr, borrowed);




  // const sellAmount = parseUnits('11184.9175', 'gwei');
  // const qs = createQueryString({
  //   sellToken: 'USDC',
  //   buyToken: 'BNT',
  //   sellAmount
  // });

  // const quoteUrl = `${API_QUOTE_URL}?${qs}`;
  // const response = await fetch(quoteUrl);
  // const quote = await response.json();
  // console.log(quote);
  // console.log(formatEther(quote.buyAmount));


}






main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
