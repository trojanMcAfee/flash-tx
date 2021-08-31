const { parseEther } = ethers.utils;

async function createPool(offchainRelayer, swaper0x, IBNT, IWETH, IWBTC) {

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

}







module.exports = {
    createPool
};