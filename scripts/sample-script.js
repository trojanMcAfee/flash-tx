const { legos } = require("@studydefi/money-legos");

const { parseEther, formatEther } = ethers.utils;

const soloMarginAddr = legos.dydx.soloMargin.address;
const wethAddr = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const borrowed = parseEther('6478.183133980298798568');
const routerAddr = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
// const myAddr = '0x715358348287f44c8113439766b9433282110F6c';

async function main() {

  const FlashLoaner = await hre.ethers.getContractFactory('FlashLoaner');
  const flashlogic = await FlashLoaner.deploy();
  await flashlogic.deployed();

  const DydxFlashloaner = await hre.ethers.getContractFactory("DydxFlashloaner");
  const flashloaner = await DydxFlashloaner.deploy(flashlogic.address);
  await flashloaner.deployed();
  console.log("Flashloaner deployed to:", flashloaner.address);

  // const router = await hre.ethers.getContractAt('IUniswapV2Router02', routerAddr);
  const signer = await hre.ethers.provider.getSigner(0);

  const IWeth = await hre.ethers.getContractAt('IWETH', wethAddr);
  const value = parseEther('2');
  await IWeth.deposit({ value });
  await IWeth.transfer(flashloaner.address, 2);


  

  


  


  // await hre.network.provider.request({
  //   method: "hardhat_impersonateAccount",
  //   params: [myAddr]
  // });

  
  await flashloaner.initiateFlashLoan(soloMarginAddr, wethAddr, borrowed);


}





// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
