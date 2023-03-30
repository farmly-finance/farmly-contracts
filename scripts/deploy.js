// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
  /*
    const FarmlyConfig = await hre.ethers.getContractFactory("FarmlyConfig");
    const farmlyConfig = await FarmlyConfig.deploy();
    await farmlyConfig.deployed();
    console.log(
      `FarmlyConfig deployed to ${farmlyConfig.address}`
    );
  
    const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
    const farmlyVault = await FarmlyVault.deploy(process.env.VAULT_TOKEN);
    await farmlyVault.deployed();
    console.log(
      `FarmlyVault deployed to ${farmlyVault.address}`
    );
  
    console.log((await farmlyConfig.setFarmingPoolVault(process.env.BASE_TOKEN, process.env.VAULT_TOKEN, farmlyVault.address)).hash, "setFarmingPoolVault");
  
  
  
    const FarmlyPositionManager = await hre.ethers.getContractFactory("FarmlyPositionManager");
    const farmlyPositionManager = await FarmlyPositionManager.deploy(farmlyConfig.address);
    await farmlyPositionManager.deployed();
    console.log(
      `FarmlyPositionManager deployed to ${farmlyPositionManager.address}`
    );
  */

  const FarmlyDexExecutor = await hre.ethers.getContractFactory("FarmlyDexExecutor");
  const farmlyDexExecutor = await FarmlyDexExecutor.deploy(process.env.PANCAKE_ROUTER);
  await farmlyDexExecutor.deployed();
  console.log(
    `FarmlyDexExecutor deployed to ${farmlyDexExecutor.address}`
  );

  // console.log((await farmlyConfig.setExecutor(farmlyDexExecutor.address, "true")).hash, "setExecutor");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});