require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity:
  {
    version: "0.8.15",
    settings: {
      // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: true,
        runs: 2000,
      },
      //  evmVersion: "byzantium"
    },
  },

  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      allowUnlimitedContractSize: true,
    },
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    arbitrumOne: {
      url: "https://arb1.arbitrum.io/rpc",
      accounts: [process.env.DEPLOYER_KEY]
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      gas: 3000000,
      accounts: [process.env.DEPLOYER_KEY]
    },
    goerli: {
      url: "https://goerli.infura.io/v3/8516a359516c40aba7c35bcf1444218a",
      chainId: 5,
      accounts: [process.env.DEPLOYER_KEY],
      gas: 3000000
    },
  }
};
