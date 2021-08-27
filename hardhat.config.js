require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.7"
      },
      {
        version: "0.8.0"
      },
      {
        version: "0.6.7"
      },
      {
        version: "0.6.12"
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

