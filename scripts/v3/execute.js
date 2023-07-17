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
    const sqrtRatioAX96 = toSqrtRatioX96((999.9));
    const sqrtRatioBX96 = toSqrtRatioX96((1400.6));
    const token0Address = "0x3ec2e8d6F81cb2b871e451fD368bD9c2b68eA09B"
    const token1Address = "0x067ADb4d5Ff41068A92D8d6dc103679eEdD07519"
    const amount0 = "50000000000000000000000"
    const amount1 = "5000000000000000000"
    const FarmlyUniV3Executor = await ethers.getContractFactory("FarmlyUniV3Executor");
    const farmlyUniV3Executor = await FarmlyUniV3Executor.attach(
        process.env.FARMLY_UNIV3_EXECUTOR_CONTRACT_ADDRESS
    );


    let IERC20 = await ethers.getContractFactory("TestToken")
    const token0 = await IERC20.attach(token0Address)
    const token1 = await IERC20.attach(token1Address)

    console.log("2726175280492281378177683686173", sqrtRatioAX96, sqrtRatioBX96, amount0, amount1, token0Address, token1Address, "500")
    //console.log((await token0.approve(farmlyUniV3Executor.address, amount0)).hash, " approve token0 ");
    //console.log((await token1.approve(farmlyUniV3Executor.address, amount1)).hash, " approve token1 ");
    const tx = await farmlyUniV3Executor.execute(sqrtRatioAX96, sqrtRatioBX96, amount0, amount1, token0Address, token1Address, "500");
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