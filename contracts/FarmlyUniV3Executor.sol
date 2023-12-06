pragma solidity >=0.5.0;

import "./interfaces/IFarmlyUniV3Executor.sol";
import "./interfaces/IFarmlyUniV3Reader.sol";
import "./interfaces/IFarmlyConfig.sol";

import "./libraries/FarmlyTransferHelper.sol";
import "./libraries/FarmlyZapV3.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FarmlyUniV3Executor is IFarmlyUniV3Executor, IERC721Receiver {
    /// @inheritdoc IFarmlyUniV3ExecutorImmutables
    INonfungiblePositionManager public override nonfungiblePositionManager;
    /// @inheritdoc IFarmlyUniV3ExecutorImmutables
    ISwapRouter public override swapRouter;
    /// @inheritdoc IFarmlyUniV3ExecutorImmutables
    IUniswapV3Factory public override factory;
    /// @inheritdoc IFarmlyUniV3ExecutorImmutables
    IFarmlyConfig public override farmlyConfig;
    /// @inheritdoc IFarmlyUniV3ExecutorImmutables
    IFarmlyUniV3Reader public override farmlyUniV3Reader;

    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager,
        ISwapRouter _swapRouter,
        IUniswapV3Factory _factory,
        IFarmlyConfig _farmlyConfig,
        IFarmlyUniV3Reader _farmlyUniV3Reader
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
        factory = _factory;
        farmlyConfig = _farmlyConfig;
        farmlyUniV3Reader = _farmlyUniV3Reader;
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IFarmlyUniV3Executor
    function execute(
        address owner,
        PositionInfo memory positionInfo
    ) public override returns (uint256) {
        (uint256 amountIn, , bool zeroForOne, ) = FarmlyZapV3.getOptimalSwap(
            V3PoolCallee.wrap(
                factory.getPool(
                    positionInfo.token0,
                    positionInfo.token1,
                    positionInfo.poolFee
                )
            ),
            positionInfo.tickLower,
            positionInfo.tickUpper,
            positionInfo.amount0Add,
            positionInfo.amount1Add
        );

        swapExactInput(
            zeroForOne ? positionInfo.token0 : positionInfo.token1,
            zeroForOne ? positionInfo.token1 : positionInfo.token0,
            amountIn,
            positionInfo.poolFee
        );

        (uint256 tokenId, uint256 amount0, uint256 amount1) = add(
            owner,
            positionInfo
        );

        emit Execute(
            tokenId,
            positionInfo.token0,
            positionInfo.token1,
            amount0,
            amount1
        );

        return tokenId;
    }

    /// @inheritdoc IFarmlyUniV3Executor
    function increase(
        uint256 uniV3PositionID,
        address owner
    )
        public
        override
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,

        ) = farmlyUniV3Reader.getPositionInfo(uniV3PositionID);

        (uint256 amountIn, , bool zeroForOne, ) = FarmlyZapV3.getOptimalSwap(
            V3PoolCallee.wrap(factory.getPool(token0, token1, fee)),
            tickLower,
            tickUpper,
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );

        swapExactInput(
            zeroForOne ? token0 : token1,
            zeroForOne ? token1 : token0,
            amountIn,
            fee
        );

        FarmlyTransferHelper.safeApprove(
            token0,
            address(nonfungiblePositionManager),
            IERC20(token0).balanceOf(address(this))
        );
        FarmlyTransferHelper.safeApprove(
            token1,
            address(nonfungiblePositionManager),
            IERC20(token1).balanceOf(address(this))
        );

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: uniV3PositionID,
                    amount0Desired: IERC20(token0).balanceOf(address(this)),
                    amount1Desired: IERC20(token1).balanceOf(address(this)),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (liquidity, amount0, amount1) = nonfungiblePositionManager
            .increaseLiquidity(params);

        if (IERC20(token0).balanceOf(address(this)) > 0)
            FarmlyTransferHelper.safeTransfer(
                token0,
                owner,
                IERC20(token0).balanceOf(address(this))
            );

        if (IERC20(token1).balanceOf(address(this)) > 0)
            FarmlyTransferHelper.safeTransfer(
                token1,
                owner,
                IERC20(token1).balanceOf(address(this))
            );

        emit Increase(uniV3PositionID, token0, token1, amount0, amount1);
    }

    /// @inheritdoc IFarmlyUniV3Executor
    function decrease(
        uint256 uniV3PositionID,
        uint24 liquidityPercent,
        uint256 debt0,
        uint256 debt1
    )
        public
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        )
    {
        (token0, token1, poolFee, , , liquidity) = farmlyUniV3Reader
            .getPositionInfo(uniV3PositionID);

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: uniV3PositionID,
                liquidity: (liquidity * liquidityPercent) / 1000000,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        _collect(uniV3PositionID, address(this));

        if (debt0 > amount0) {
            uint256 amountIn = swapExactOutput(
                token1,
                token0,
                debt0 - amount0,
                poolFee
            );

            amount0 += debt0 - amount0;
            amount1 -= amountIn;
        } else if (debt1 > amount1) {
            uint256 amountIn = swapExactOutput(
                token0,
                token1,
                debt1 - amount1,
                poolFee
            );

            amount1 += debt1 - amount1;
            amount0 -= amountIn;
        }

        FarmlyTransferHelper.safeTransfer(
            token0,
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );

        FarmlyTransferHelper.safeTransfer(
            token1,
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );

        emit Decrease(uniV3PositionID, token0, token1, amount0, amount1);
    }

    /// @inheritdoc IFarmlyUniV3Executor
    function collect(
        uint256 uniV3PositionID,
        address owner
    )
        public
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        )
    {
        (amount0, amount1) = _collect(uniV3PositionID, address(this));

        (token0, token1, , , , ) = farmlyUniV3Reader.getPositionInfo(
            uniV3PositionID
        );

        uint256 amount0Fee = (amount0 * farmlyConfig.uniPerformanceFee()) /
            1000000;

        uint256 amount1Fee = (amount1 * farmlyConfig.uniPerformanceFee()) /
            1000000;

        amount0 -= amount0Fee;
        amount1 -= amount1Fee;

        FarmlyTransferHelper.safeTransfer(token0, owner, amount0);
        FarmlyTransferHelper.safeTransfer(token1, owner, amount1);

        FarmlyTransferHelper.safeTransfer(
            token0,
            farmlyConfig.feeAddress(),
            amount0Fee
        );
        FarmlyTransferHelper.safeTransfer(
            token1,
            farmlyConfig.feeAddress(),
            amount1Fee
        );

        emit Collect(uniV3PositionID, token0, token1, amount0, amount1);
    }

    /// @inheritdoc IFarmlyUniV3Executor
    function close(
        uint256 uniV3PositionID,
        uint256 debt0,
        uint256 debt1
    )
        public
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        )
    {
        (token0, token1, poolFee, , , liquidity) = farmlyUniV3Reader
            .getPositionInfo(uniV3PositionID);

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: uniV3PositionID,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        _collect(uniV3PositionID, address(this));

        if (debt0 > amount0) {
            uint256 amountIn = swapExactOutput(
                token1,
                token0,
                debt0 - amount0,
                poolFee
            );

            amount0 += debt0 - amount0;
            amount1 -= amountIn;
        } else if (debt1 > amount1) {
            uint256 amountIn = swapExactOutput(
                token0,
                token1,
                debt1 - amount1,
                poolFee
            );

            amount1 += debt1 - amount1;
            amount0 -= amountIn;
        }

        FarmlyTransferHelper.safeTransfer(
            token0,
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );

        FarmlyTransferHelper.safeTransfer(
            token1,
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );

        emit Close(uniV3PositionID, token0, token1, amount0, amount1);
    }

    /// Swap tokens with exact input by calling to ISwapRouter
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint24 poolFee
    ) private returns (uint amountOut) {
        FarmlyTransferHelper.safeApprove(
            tokenIn,
            address(swapRouter),
            amountIn
        );

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /// Swap tokens with exact output by calling to ISwapRouter
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint24 poolFee
    ) private returns (uint amountIn) {
        FarmlyTransferHelper.safeApprove(
            tokenIn,
            address(swapRouter),
            2 ** 256 - 1
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: 2 ** 256 - 1,
                sqrtPriceLimitX96: 0
            });

        amountIn = swapRouter.exactOutputSingle(params);
        FarmlyTransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
    }

    /// Add tokens to the position with minting a new position
    /// by calling to INonfungiblePositionManager
    function add(
        address owner,
        PositionInfo memory positionInfo
    ) private returns (uint256 tokenId, uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(
                positionInfo.token0,
                positionInfo.token1,
                positionInfo.poolFee
            )
        );

        (positionInfo.token0, positionInfo.token1) = positionInfo.token0 ==
            pool.token0()
            ? (positionInfo.token0, positionInfo.token1)
            : (positionInfo.token1, positionInfo.token0);

        IERC20 token0 = IERC20(positionInfo.token0);
        IERC20 token1 = IERC20(positionInfo.token1);

        FarmlyTransferHelper.safeApprove(
            positionInfo.token0,
            address(nonfungiblePositionManager),
            token0.balanceOf(address(this))
        );
        FarmlyTransferHelper.safeApprove(
            address(positionInfo.token1),
            address(nonfungiblePositionManager),
            token1.balanceOf(address(this))
        );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: positionInfo.token0,
                token1: positionInfo.token1,
                fee: positionInfo.poolFee,
                tickLower: positionInfo.tickLower,
                tickUpper: positionInfo.tickUpper,
                amount0Desired: token0.balanceOf(address(this)),
                amount1Desired: token1.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, , amount0, amount1) = nonfungiblePositionManager.mint(params);

        if (token0.balanceOf(address(this)) > 0)
            FarmlyTransferHelper.safeTransfer(
                positionInfo.token0,
                owner,
                token0.balanceOf(address(this))
            );

        if (token1.balanceOf(address(this)) > 0)
            FarmlyTransferHelper.safeTransfer(
                positionInfo.token1,
                owner,
                token1.balanceOf(address(this))
            );
    }

    /// Collect position trading fees rewards by calling to INonfungiblePositionManager
    function _collect(
        uint256 uniV3PositionID,
        address receiver
    ) private returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(
                uniV3PositionID,
                receiver,
                type(uint128).max,
                type(uint128).max
            )
        );
    }
}
