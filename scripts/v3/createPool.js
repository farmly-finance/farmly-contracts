// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const [owner, signer2] = await ethers.getSigners();
    const factory = await ethers.getContractAt("IUniswapV3Factory", process.env.UNISWAP_V3_FACTORY_CONTRACT_ADDRESS);
    // first call
    console.log(await factory.connect(owner).createPool(process.env.VAULT_TOKEN, process.env.VAULT_TOKEN_2, "500", { gasLimit: 5000000 }), "created pool")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});