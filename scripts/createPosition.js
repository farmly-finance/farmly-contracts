// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

async function main() {
    // 000000000000000000
    const debtAmount = "20000000000000000000000" // 20000
    const debtTokenAmount = "5000000000000000000000" // 5000
    const tokenAmount = "5000000000000000000000" // 5000
    const FarmlyPositionManager = await ethers.getContractFactory("FarmlyPositionManager");
    const farmlyPositionManager = await FarmlyPositionManager.attach(
        process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS
    );
    const tx = await farmlyPositionManager.createPosition(process.env.BASE_TOKEN, process.env.VAULT_TOKEN, tokenAmount, debtTokenAmount, debtAmount, process.env.FARMLY_DEX_EXECUTOR_CONTRACT_ADDRESS)
    console.log(tx.hash, "position created")


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/*

function createPosition(
        IERC20 token,
        IERC20 debtToken,
        uint256 tokenAmount,
        uint256 debtTokenAmount,
        uint256 debtAmount,
        address executor

*/