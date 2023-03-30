// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const ROUTER = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506"
  const VAULT_TOKEN = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
  const USDC = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8"
  /*
    const FarmlyConfig = await hre.ethers.getContractFactory("FarmlyConfig");
    const farmlyConfig = await FarmlyConfig.deploy();
    await farmlyConfig.deployed();
    console.log(
      `FarmlyConfig deployed to ${farmlyConfig.address}`
    );
  
    const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
    const farmlyVault = await FarmlyVault.deploy(VAULT_TOKEN);
    await farmlyVault.deployed();
    console.log(
      `FarmlyVault deployed to ${farmlyVault.address}`
    );
  
    console.log((await farmlyConfig.setFarmingPoolVault(USDC, VAULT_TOKEN, farmlyVault.address)).hash, "setFarmingPoolVault");
  */

  const FarmlyPositionManager = await hre.ethers.getContractFactory("FarmlyPositionManager");
  const farmlyPositionManager = await FarmlyPositionManager.deploy("0xD5Ccf53b66af850D237da0c695Bfcbd9b77f2fe4");
  await farmlyPositionManager.deployed();
  console.log(
    `FarmlyPositionManager deployed to ${farmlyPositionManager.address}`
  );

  /*
    const FarmlyDexExecutor = await hre.ethers.getContractFactory("FarmlyDexExecutor");
    const farmlyDexExecutor = await FarmlyDexExecutor.deploy(ROUTER);
    await farmlyDexExecutor.deployed();
    console.log(
      `FarmlyDexExecutor deployed to ${farmlyDexExecutor.address}`
    );
    /*
      console.log((await farmlyConfig.setExecutor(farmlyDexExecutor.address, "true")).hash, "setExecutor");
    */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
/* 

unlockTime, { value: lockedAmount }
 

  */