require("@nomiclabs/hardhat-waffle");

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
        url: 'https://eth-mainnet.alchemyapi.io/v2/aHdZRYTN-8_SDXHT0gOEh4XtAuhT7E-W',
        blockNumber: 12431519
      }
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/ead605dd65704007ae941fffb7c1d1a7'
    }
  }
};

