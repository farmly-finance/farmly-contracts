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
    const TestUSDC = await hre.ethers.getContractFactory("TestUSDC");
    const testUSDC = await TestUSDC.deploy();
    await testUSDC.deployed();
    console.log(
      `TestUSDC deployed to ${testUSDC.address}`
    );
  
    const TestWETH = await hre.ethers.getContractFactory("TestWETH");
    const testWETH = await TestWETH.deploy();
    await testWETH.deployed();
    console.log(
      `TestWETH deployed to ${testWETH.address}`
    );
  
 
    */

  /*
    const FarmlyInterestModel = await hre.ethers.getContractFactory("FarmlyInterestModel");
    const farmlyInterestModel = await FarmlyInterestModel.deploy();
    await farmlyInterestModel.deployed();
    console.log(
      `farmlyInterestModel deployed to ${farmlyInterestModel.address}`
    );
  
    const farmlyInterestModel2 = await FarmlyInterestModel.deploy();
    await farmlyInterestModel2.deployed();
    console.log(
      `farmlyInterestModel2 deployed to ${farmlyInterestModel2.address}`
    );
  
    const FarmlyConfig = await hre.ethers.getContractFactory("FarmlyConfig");
    const farmlyConfig = await FarmlyConfig.deploy();
    await farmlyConfig.deployed();
    console.log(
      `FarmlyConfig deployed to ${farmlyConfig.address}`
    );
    */
  /*
    const FarmlyVault = await hre.ethers.getContractFactory("FarmlyVault");
    const farmlyVault = await FarmlyVault.deploy(process.env.VAULT_TOKEN, "Farmly USDC Interest Bearing", "flyUSDC");
    await farmlyVault.deployed();
    console.log(
      `FarmlyVault deployed to ${farmlyVault.address}`
    );
  
    const FarmlyVault2 = await hre.ethers.getContractFactory("FarmlyVault");
    const farmlyVault2 = await FarmlyVault2.deploy(process.env.VAULT_TOKEN_2, "Farmly ETH Interest Bearing", "flyETH");
    await farmlyVault2.deployed();
    console.log(
      `FarmlyVault2 deployed to ${farmlyVault2.address}`
    );
    */

  /*
  await farmlyConfig.setVaultInterestModel(farmlyVault.address, farmlyInterestModel.address);
  console.log("Vault Interest Model Setted")
  await farmlyConfig.setVaultInterestModel(farmlyVault2.address, farmlyInterestModel2.address);
  console.log("Vault Interest Model Setted")
  */
  /*

  const FarmlyPriceConsumer = await hre.ethers.getContractFactory("FarmlyPriceConsumer");
  const farmlyPriceConsumer = await FarmlyPriceConsumer.deploy();
  await farmlyPriceConsumer.deployed();
  console.log(
    `FarmlyPriceConsumer deployed to ${farmlyPriceConsumer.address}`
  );
  const FarmlyUniV3Reader = await hre.ethers.getContractFactory("FarmlyUniV3Reader");
  const farmlyUniV3Reader = await FarmlyUniV3Reader.deploy();
  await farmlyUniV3Reader.deployed();
  console.log(
    `FarmlyUniV3Reader deployed to ${farmlyUniV3Reader.address}`
  );
  */
  const FarmlyPositionManager = await hre.ethers.getContractFactory("FarmlyPositionManager");
  const farmlyPositionManager = await FarmlyPositionManager.deploy();
  await farmlyPositionManager.deployed();
  console.log(
    `FarmlyPositionManager deployed to ${farmlyPositionManager.address}`
  );
  const FarmlyVault = await ethers.getContractFactory("FarmlyVault");
  const farmlyVault = await FarmlyVault.attach(
    process.env.FARMLY_VAULT_CONTRACT_ADDRESS
  );
  const farmlyVault2 = await FarmlyVault.attach(
    process.env.FARMLY_VAULT_2_CONTRACT_ADDRESS
  );
  await farmlyVault.addBorrower(farmlyPositionManager.address);
  await farmlyVault2.addBorrower(farmlyPositionManager.address);
  const FarmlyUniV3Executor = await hre.ethers.getContractFactory("FarmlyUniV3Executor");
  const farmlyUniV3Executor = await FarmlyUniV3Executor.deploy();
  await farmlyUniV3Executor.deployed();
  console.log(
    `FarmlyUniV3Executor deployed to ${farmlyUniV3Executor.address}`
  );

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});