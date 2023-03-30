// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {

    const FarmlyVault = await ethers.getContractFactory("FarmlyVault");
    const farmlyVault = await FarmlyVault.attach(
        process.env.FARMLY_VAULT_CONTRACT_ADDRESS
    );


    console.log(await farmlyVault.pendingInterest(0), "Pending interest");
    console.log(await farmlyVault.totalDebt(), "totalDebt");
    console.log(await farmlyVault.totalDebtShare(), "totalDebtShare");
    console.log(await farmlyVault.token(), "token");
    console.log(await farmlyVault.lastAction(), "lastAction");
    console.log(await farmlyVault.totalToken(), "totalToken");
    console.log(await farmlyVault.totalSupply(), "totalSupply");
    console.log("1 flyETH = ", (await farmlyVault.totalToken()) / (await farmlyVault.totalSupply()), " ETH");


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});