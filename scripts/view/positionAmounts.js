// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {

    const FarmlyUniV3Executor = await ethers.getContractFactory("FarmlyUniV3Executor");
    const farmlyUniV3Executor = await FarmlyUniV3Executor.attach(
        process.env.FARMLY_UNIV3_EXECUTOR_CONTRACT_ADDRESS
    );

    const amounts = await farmlyUniV3Executor.getPositionAmounts("73760")
    console.log(amounts)
    console.log(amounts.amount0.toString(), "amounts");


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});