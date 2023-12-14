pragma solidity >=0.5.0;

import "./interfaces/IFarmlyUniV3Reader.sol";
import "./interfaces/IFarmlyPriceConsumer.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import {FarmlyZapV3, V3PoolCallee} from "./libraries/FarmlyZapV3.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

contract FarmlyUniV3Reader is IFarmlyUniV3Reader {
    /// @inheritdoc IFarmlyUniV3Reader
    INonfungiblePositionManager public override nonfungiblePositionManager;
    /// @inheritdoc IFarmlyUniV3Reader
    IUniswapV3Factory public override factory;
    /// @inheritdoc IFarmlyUniV3Reader
    IFarmlyPriceConsumer public override farmlyPriceConsumer;

    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager,
        IUniswapV3Factory _factory,
        IFarmlyPriceConsumer _farmlyPriceConsumer
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        factory = _factory;
        farmlyPriceConsumer = _farmlyPriceConsumer;
    }

    /// @inheritdoc IFarmlyUniV3Reader
    function getPositionAmounts(
        uint256 uniV3PositionID
    ) public view override returns (uint256 amount0, uint256 amount1) {
        (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        ) = getPositionInfo(uniV3PositionID);

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

    /// @inheritdoc IFarmlyUniV3Reader
    function getPositionInfo(
        uint256 uniV3PositionID
    )
        public
        view
        override
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

    /// @inheritdoc IFarmlyUniV3Reader
    function getPositionUSDValue(
        uint256 uniV3PositionID
    )
        public
        view
        override
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

    /// @inheritdoc IFarmlyUniV3Reader
    function getAmountsForAdd(
        IFarmlyUniV3Executor.PositionInfo memory positionInfo
    )
        public
        view
        override
        returns (
            IFarmlyUniV3Executor.SwapInfo memory swapInfo,
            uint256 amount0Add,
            uint256 amount1Add
        )
    {
        address pool = factory.getPool(
            positionInfo.token0,
            positionInfo.token1,
            positionInfo.poolFee
        );

        (
            uint256 amountIn,
            uint256 amountOut,
            bool zeroForOne,
            uint160 sqrtPriceX96
        ) = FarmlyZapV3.getOptimalSwap(
                V3PoolCallee.wrap(pool),
                positionInfo.tickLower,
                positionInfo.tickUpper,
                positionInfo.amount0Add,
                positionInfo.amount1Add
            );

        swapInfo.tokenIn = zeroForOne
            ? positionInfo.token0
            : positionInfo.token1;

        swapInfo.tokenOut = zeroForOne
            ? positionInfo.token1
            : positionInfo.token0;

        swapInfo.amountIn = amountIn;

        swapInfo.amountOut = amountOut;

        swapInfo.sqrtPriceX96 = sqrtPriceX96;

        amount0Add = zeroForOne
            ? positionInfo.amount0Add - amountIn
            : positionInfo.amount0Add + amountOut;

        amount1Add = zeroForOne
            ? positionInfo.amount1Add + amountOut
            : positionInfo.amount1Add - amountIn;
    }
}
