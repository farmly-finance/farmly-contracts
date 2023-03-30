// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {

    const FarmlyConfig = await ethers.getContractFactory("FarmlyConfig");
    const farmlyConfig = await FarmlyConfig.attach(
        process.env.FARMLY_CONFIG_CONTRACT_ADDRESS
    );



    console.log((await farmlyConfig.setExecutor(process.env.FARMLY_DEX_EXECUTOR_CONTRACT_ADDRESS, "true")).hash, "setExecutor")


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});