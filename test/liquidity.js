const { expect } = require("chai");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

function toSqrtRatioX96(val) {
    return (Math.sqrt(val) * (2 ** 96)).toLocaleString('fullwide', { useGrouping: false });
}

describe("Liquidity", function () {
    it("...", async function () {
        let sqrtRatioX96 = toSqrtRatioX96(1e12 / 1850); // 1850
        const sqrtRatioAX96 = toSqrtRatioX96(1e12 / 1750); // 1750
        const sqrtRatioBX96 = toSqrtRatioX96(1e12 / 2000); // 2000
        console.log(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96)
        const amount0 = "1325759297"
        const amount1 = "1000000000000000000"

        const begin = 1325.75 + (1850)
        console.log(1850, begin, "totalPositionValue", 0)
        console.log("---------------------------------------------")
        console.log(1850, begin * 3, "totalPositionValue3X", 0)
        console.log("---------------------------------------------")
        console.log(1850, begin * 3 - begin, "totalDebt", (begin * 2) / (begin * 3), "debtRatio")
        console.log("---------------------------------------------")
        console.log("---------------------------------------------")
        console.log("---------------------------------------------")
        const LiquidityAmountsLib = await hre.ethers.getContractFactory("LiquidityAmountsLib");
        const liquidityAmountsLib = await LiquidityAmountsLib.deploy();
        const liquidity = await liquidityAmountsLib.getLiquidityForAmounts(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, amount0, amount1)

        for (let i = 1740; i <= 2010; i += 10) {
            sqrtRatioX96 = toSqrtRatioX96(1e12 / i); // 1950

            const amounts = await liquidityAmountsLib.getAmountsForLiquidity(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, liquidity)
            const _amount0 = amounts.amount0 / 1e6
            const _amount1 = amounts.amount1 / 1e18
            const totalPositionValue = (_amount1 * i) + _amount0
            const totalPositionValue3X = 3 * totalPositionValue
            console.log(i, totalPositionValue.toFixed(2), "totalPositionValue", (totalPositionValue - begin).toFixed(2))
            console.log(i, totalPositionValue3X.toFixed(2), "totalPositionValue3X", (totalPositionValue3X - (begin * 3)).toFixed(2))
            console.log(i, (3.42167567568 * i).toFixed(2), "totalDebt", (3.42167567568 * i / totalPositionValue3X) > 0.87 ? "liquidated" : (3.42167567568 * i / totalPositionValue3X).toFixed(4), "debtRatio")
            console.log("---------------------------------------------")
        }

    });

    /* 
       uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1




           uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    */
});