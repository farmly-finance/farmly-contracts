// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const debtTokenAmount = "5000000000000000000000"
    const tokenAmount = "5000000000000000000000"


    const IERC20 = await ethers.getContractFactory("TestToken");
    const vaultToken = await IERC20.attach(
        process.env.VAULT_TOKEN
    );

    const baseToken = await IERC20.attach(
        process.env.BASE_TOKEN
    );


    console.log((await vaultToken.approve(process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS, debtTokenAmount)).hash, "approve debtTokenAmount")
    console.log((await baseToken.approve(process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS, tokenAmount)).hash, "approve tokenAmount")


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});