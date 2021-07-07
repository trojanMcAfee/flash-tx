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
    ropsten: {
      url: 'https://ropsten.infura.io/v3/ead605dd65704007ae941fffb7c1d1a7',
      accounts: ['8935b1c4367a5e046b9c0a51092bbcf3d69a5f6fa33960fc858a05c35c2d7e3a']
    }
  }
};

