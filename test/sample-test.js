const { assert } = require("chai");

describe("Greeter", function() {

  

  it("Should return the new greeting once it's changed", async function() {
    const Relayer0x = await ethers.getContractFactory("Relayer0x");
    const relayer0x = await Relayer0x.deploy();
    await relayer0x.deployed();

    await relayer0x.executeSwap();
  });
});
