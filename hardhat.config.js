require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.15",
  networks: {
    arbitrumOne: {
      url: "https://arb1.arbitrum.io/rpc",
      accounts: [process.env.DEPLOYER_KEY]
    }
  }
};
