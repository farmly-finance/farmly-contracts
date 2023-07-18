// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {

    const FarmlyPositionManager = await ethers.getContractFactory("FarmlyPositionManager");
    const farmlyPositionManager = await FarmlyPositionManager.attach(
        process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS
    );


    const usdValue = await farmlyPositionManager.getDebtUSDValue(process.env.FARMLY_UNIV3_EXECUTOR_CONTRACT_ADDRESS, "1")
    console.log(usdValue.debt0USD / 1e18, "debt0USD")
    console.log(usdValue.debt1USD / 1e18, "debt1USD")
    console.log(usdValue.debtUSD / 1e18, "debtUSD");


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});