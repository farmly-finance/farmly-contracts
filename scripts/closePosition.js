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

    const FarmlyPositionManager = await ethers.getContractFactory("FarmlyPositionManager");
    const farmlyPositionManager = await FarmlyPositionManager.attach(
        process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS
    );

    const tx = await farmlyPositionManager.closePosition("1");
    console.log(tx.hash, "position closed")


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