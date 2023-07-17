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
    const nPositionManager = await ethers.getContractAt("INonfungiblePositionManager", process.env.NONFUNGIBLE_POSITION_MANAGER_CONTRACT_ADDRESS);
    // first call

    const params = {
        token0: process.env.VAULT_TOKEN,
        token1: process.env.VAULT_TOKEN_2,
        fee: "500",
        tickLower: "200",
        tickUpper: "400",
        amount0Desired: "100000",
        amount1Desired: "100000",
        amount0Min: 0,
        amount1Min: 0,
        recipient: owner.address,
        deadline: Math.floor(Date.now() / 1000) + (60 * 10)
    }
    console.log(await nPositionManager.connect(owner).mint(params, { gasLimit: 5000000 }), "created pool")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});