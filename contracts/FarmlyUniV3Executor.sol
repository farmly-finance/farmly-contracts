pragma solidity >=0.5.0;
pragma abicoder v2;

import "./library/LiquidityAmountsLib.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

contract FarmlyUniV3Executor is IERC721Receiver, LiquidityAmountsLib {
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Factory public constant factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function execute(
        address owner,
        uint256 amount0Has,
        uint256 amount1Has,
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public returns (uint256 tokenId) {
        positionInfo.token0.transferFrom(msg.sender, address(this), amount0Has);
        positionInfo.token1.transferFrom(msg.sender, address(this), amount1Has);

        swapExactInput(
            swapInfo.tokenIn,
            swapInfo.tokenOut,
            swapInfo.amountIn,
            positionInfo.poolFee
        );
        IUniswapV3Pool pool = IUniswapV3Pool(
            factory.getPool(
                address(positionInfo.token0),
                address(positionInfo.token1),
                positionInfo.poolFee
            )
        );

        tokenId = add(
            owner,
            address(positionInfo.token0) == pool.token0()
                ? positionInfo.token0
                : positionInfo.token1,
            address(positionInfo.token1) == pool.token1()
                ? positionInfo.token1
                : positionInfo.token0,
            positionInfo.poolFee,
            positionInfo.sqrtRatioAX96,
            positionInfo.sqrtRatioBX96
        );
    }

    function increase(
        uint256 uniV3PositionID,
        address owner,
        uint256 amount0Has,
        uint256 amount1Has,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        (address token0, address token1, uint24 fee, , , ) = getPositionData(
            uniV3PositionID
        );

        TransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount0Has
        );

        TransferHelper.safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amount1Has
        );

        swapExactInput(
            swapInfo.tokenIn,
            swapInfo.tokenOut,
            swapInfo.amountIn,
            fee
        );

        TransferHelper.safeApprove(
            token0,
            address(nonfungiblePositionManager),
            IERC20(token0).balanceOf(address(this))
        );
        TransferHelper.safeApprove(
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
            TransferHelper.safeTransfer(
                token0,
                owner,
                IERC20(token0).balanceOf(address(this))
            );

        if (IERC20(token1).balanceOf(address(this)) > 0)
            TransferHelper.safeTransfer(
                token1,
                owner,
                IERC20(token1).balanceOf(address(this))
            );
    }

    function decrease(
        uint256 uniV3PositionID,
        uint24 liquidityPercent,
        uint256 debt0,
        uint256 debt1
    )
        public
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        )
    {
        (
            ,
            ,
            token0,
            token1,
            poolFee,
            ,
            ,
            liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(uniV3PositionID);

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

        IERC20(token0).transfer(
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).transfer(
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );

        /*
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint24 poolFee
        */
    }

    function collect(
        uint256 uniV3PositionID
    )
        public
        returns (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        )
    {
        (amount0, amount1) = _collect(uniV3PositionID, msg.sender);

        (, , token0, token1, , , , , , , , ) = nonfungiblePositionManager
            .positions(uniV3PositionID);
    }

    function close(
        uint256 uniV3PositionID,
        uint256 debt0,
        uint256 debt1
    )
        public
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        )
    {
        (
            ,
            ,
            token0,
            token1,
            poolFee,
            ,
            ,
            liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(uniV3PositionID);

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

        IERC20(token0).transfer(
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).transfer(
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );

        /*
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint24 poolFee
        */
    }

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

    function swapExactInput(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint24 poolFee
    ) private returns (uint amountOut) {
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);

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

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint24 poolFee
    ) private returns (uint amountIn) {
        TransferHelper.safeApprove(tokenIn, address(swapRouter), 2 ** 256 - 1);

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

        // The call to `exactInputSingle` executes the swap.
        amountIn = swapRouter.exactOutputSingle(params);
        TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
    }

    function add(
        address owner,
        IERC20Metadata token0,
        IERC20Metadata token1,
        uint24 poolFee,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96
    ) private returns (uint256 tokenId) {
        TransferHelper.safeApprove(
            address(token0),
            address(nonfungiblePositionManager),
            token0.balanceOf(address(this))
        );
        TransferHelper.safeApprove(
            address(token1),
            address(nonfungiblePositionManager),
            token1.balanceOf(address(this))
        );

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(token0),
                token1: address(token1),
                fee: poolFee,
                tickLower: TickMath.getTickAtSqrtRatio(sqrtRatioAX96),
                tickUpper: TickMath.getTickAtSqrtRatio(sqrtRatioBX96),
                amount0Desired: token0.balanceOf(address(this)),
                amount1Desired: token1.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be created and initialized in order to mint
        (tokenId, , , ) = nonfungiblePositionManager.mint(params);

        if (token0.balanceOf(address(this)) > 0)
            token0.transfer(owner, token0.balanceOf(address(this)));

        if (token1.balanceOf(address(this)) > 0)
            token1.transfer(owner, token1.balanceOf(address(this)));
    }

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

    function getPositionData(
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
}
