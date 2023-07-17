// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require('dotenv').config();

function toSqrtRatioX96(val) {
    return (Math.sqrt(val) * (2 ** 96)).toLocaleString('fullwide', { useGrouping: false });
}
async function main() {
    const executor = process.env.FARMLY_UNIV3_EXECUTOR_CONTRACT_ADDRESS
    const sqrtRatioAX96 = toSqrtRatioX96((999.9));
    const sqrtRatioBX96 = toSqrtRatioX96((1400.6));
    const amount0 = "5000000000000000000000"
    const amount1 = "5000000000000000000"
    const FarmlyPositionManager = await ethers.getContractFactory("FarmlyPositionManager");
    const farmlyPositionManager = await FarmlyPositionManager.attach(
        process.env.FARMLY_POSITION_MANAGER_CONTRACT_ADDRESS
    );

    console.log(executor, amount0, amount1,
        [process.env.FARMLY_VAULT_CONTRACT_ADDRESS, "10000000000000000000000"],
        [process.env.FARMLY_VAULT_2_CONTRACT_ADDRESS, "10000000000000000000"],
        [process.env.VAULT_TOKEN, process.env.VAULT_TOKEN_2, "500", sqrtRatioAX96, sqrtRatioBX96, "17067725986131680000000", "13264509705127800000"],
        [process.env.VAULT_TOKEN_2, process.env.VAULT_TOKEN, "1735490294872200000"])

    let IERC20 = await ethers.getContractFactory("TestWETH")
    const token0 = await IERC20.attach(process.env.VAULT_TOKEN)
    const token1 = await IERC20.attach(process.env.VAULT_TOKEN_2)

    //console.log((await token0.approve(farmlyPositionManager.address, amount0)).hash, " approve token0 ");
    //console.log((await token1.approve(farmlyPositionManager.address, amount1)).hash, " approve token1 ");
    const tx = await farmlyPositionManager.createPosition(executor, amount0, amount1,
        [process.env.FARMLY_VAULT_CONTRACT_ADDRESS, "10000000000000000000000"],
        [process.env.FARMLY_VAULT_2_CONTRACT_ADDRESS, "10000000000000000000"],
        [process.env.VAULT_TOKEN, process.env.VAULT_TOKEN_2, "500", sqrtRatioAX96, sqrtRatioBX96, "17067725986131680000000", "13264509705127800000"],
        [process.env.VAULT_TOKEN_2, process.env.VAULT_TOKEN, "1735490294872200000"]);
    console.log(tx.hash, "position created")

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

/*

 function execute(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0Has,
        uint256 amount1Has,
        IERC20 token0,
        IERC20 token1,
        uint24 poolFee
    ) 
    
    */