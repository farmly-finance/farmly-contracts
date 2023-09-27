pragma solidity >=0.5.0;
pragma abicoder v2;

import "./library/LiquidityAmountsLib.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./library/FarmlyTransferHelper.sol";
import "./interfaces/IFarmlyPriceConsumer.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

contract FarmlyUniV3Reader {
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public constant factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IFarmlyPriceConsumer public farmlyPriceConsumer =
        IFarmlyPriceConsumer(0xF28f90B3c87e075eC5749383DC055dba72835B15);

    function getPositionAmounts(
        uint256 uniV3PositionID
    ) public view returns (uint256 amount0, uint256 amount1) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(uniV3PositionID);

        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(token0, token1, fee)
        );

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );
    }

    function getPositionInfo(
        uint256 uniV3PositionID
    )
        public
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        )
    {
        (
            ,
            ,
            token0,
            token1,
            fee,
            tickLower,
            tickUpper,
            liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(uniV3PositionID);
    }

    function getPositionUSDValue(
        uint256 uniV3PositionID
    )
        public
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD)
    {
        (address token0, address token1, , , , ) = getPositionInfo(
            uniV3PositionID
        );
        (uint256 amount0, uint256 amount1) = getPositionAmounts(
            uniV3PositionID
        );

        token0USD = farmlyPriceConsumer.calcUSDValue(token0, amount0);
        token1USD = farmlyPriceConsumer.calcUSDValue(token1, amount1);
        totalUSD = token0USD + token1USD;
    }
}
