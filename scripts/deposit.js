// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const depositAmount = "100000000000000000000000"


    const IERC20 = await ethers.getContractFactory("TestToken");
    const vaultToken = await IERC20.attach(
        process.env.VAULT_TOKEN
    );

    const FarmlyVault = await ethers.getContractFactory("FarmlyVault");
    const farmlyVault = await FarmlyVault.attach(
        process.env.FARMLY_VAULT_CONTRACT_ADDRESS
    );


    console.log((await vaultToken.approve(farmlyVault.address, depositAmount)).hash, "approved for 100k tokens")
    console.log((await farmlyVault.deposit(depositAmount)).hash, "deposited 100k tokens")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});