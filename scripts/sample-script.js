const { legos } = require("@studydefi/money-legos");
const fetch = require("node-fetch");
const { createQueryString, API_QUOTE_URL } = require('./relayer');


const { parseEther, parseUnits, formatEther } = ethers.utils;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const borrowed = parseEther('6478');
let value;
// const routerAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
// const myAddr = '0x715358348287f44c8113439766b9433282110F6c';
// const ORACLES = {
//   addresses: [
//     0x5b4247e58fe5a54a116e4a3be32b31be7030c8a3,
//     0x688e8432e12620474d53b4a26eb2e84ebed4245c,
//     0x2ed7e9fcd3c0568dc6167f0b8aee06a02cd9ebd8
//   ],
//   jobIds: [
//     e67ddf1f394d44e79a9a2132efd00050,
//     f2335e15bff140f4a26cee888c2ccfbf,
//     a32d79b72f28437b8a30788ca62b0f21
//   ],
//   payments: [
//     parseEther('1'),
//     parseEther('1'),
//     parseEther('1')
//   ]
// };


async function main() {
  const signer = await hre.ethers.provider.getSigner(0);
  const signerAddr = await signer.getAddress();
  console.log('Deployers address: ', signerAddr);
  
  const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner');
  const flashlogic = await FlashLoaner.deploy();
  await flashlogic.deployed();
  
  const DydxFlashloaner = await hre.ethers.getContractFactory("DydxFlashloaner");
  const dxdxFlashloaner = await DydxFlashloaner.deploy(flashlogic.address, borrowed);
  await dxdxFlashloaner.deployed();
  console.log("dYdX_flashloaner deployed to:", dxdxFlashloaner.address);

  //Sends 2 gwei to the Proxy contract (dYdX flashloaner)
  const IWeth = await hre.ethers.getContractAt('IWETH', wethAddr);
  value = parseUnits('2', "gwei");
  await IWeth.deposit({ value });
  await IWeth.transfer(dxdxFlashloaner.address, value);

  // value = parseEther('1');
  // await IWeth.deposit({ value });
  // await IWeth.transfer(flashlogic.address, value); //sending the ETH for paying fees
  



  //Creates the Service Agreement that will be used by the Chainlink nodes to make the 0x API calls
  const PreCoordinator = await hre.ethers.getContractFactory('PreCoordinator');
  const precoordinator = await PreCoordinator.deploy();
  await precoordinator.deployed();
  const tx = await precoordinator.createServiceAgreement();
  const receipt = await tx.wait();
  console.log('Pre-Coordinator address: ', precoordinator.address);
  console.log('Service Agreement ID: ', receipt.logs[0].topics[1]);
  


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
