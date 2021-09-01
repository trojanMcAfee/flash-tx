require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.0"
      }
    ]
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_URL,
        blockNumber: 12431519
      }
    }
  }
};

