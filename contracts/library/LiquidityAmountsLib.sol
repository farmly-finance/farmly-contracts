pragma solidity ^0.8.0;
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./FarmlyFullMath.sol";

contract LiquidityAmountsLib {
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) public pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0,
                amount1
            );
    }

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public pure returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );
    }

    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
    }

    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        return
            LiquidityAmounts.getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        return
            LiquidityAmounts.getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }

    function getAmountsForAddingLiquidity(
        uint256 price,
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0Has,
        uint256 amount1Has,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public pure returns (uint256 amount0, uint256 amount1, bool is01) {
        uint _amount0 = (10 ** (token0Decimals + token1Decimals)) /
            (FarmlyFullMath.mulDiv(
                FarmlyFullMath.mulDiv(
                    sqrtRatioX96,
                    sqrtRatioBX96,
                    2 ** (96 * 2)
                ),
                (sqrtRatioX96 - sqrtRatioAX96),
                (sqrtRatioBX96 - sqrtRatioX96)
            ) * (10 ** token0Decimals));
        uint total = _amount0 + price;
        uint totalAmounts = amount0Has +
            ((amount1Has * price) / (10 ** token1Decimals));
        amount0 = FarmlyFullMath.mulDiv(totalAmounts, _amount0, total);
        amount1 = FarmlyFullMath.mulDiv(
            totalAmounts,
            10 ** token1Decimals,
            total
        );

        is01 = amount0Has > amount0 ? true : false;
    }
}
