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
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo
    ) public returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        positionInfo.token0.transferFrom(msg.sender, address(this), amount0Has);
        positionInfo.token1.transferFrom(msg.sender, address(this), amount1Has);

        swapExactInput(
            swapInfo.tokenIn,
            swapInfo.tokenOut,
            swapInfo.amountIn,
            positionInfo.poolFee
        );

        TransferHelper.safeApprove(
            address(positionInfo.token0),
            address(nonfungiblePositionManager),
            positionInfo.token0.balanceOf(address(this))
        );
        TransferHelper.safeApprove(
            address(positionInfo.token1),
            address(nonfungiblePositionManager),
            positionInfo.token1.balanceOf(address(this))
        );

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: uniV3PositionID,
                    amount0Desired: positionInfo.token0.balanceOf(
                        address(this)
                    ),
                    amount1Desired: positionInfo.token1.balanceOf(
                        address(this)
                    ),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });

        (liquidity, amount0, amount1) = nonfungiblePositionManager
            .increaseLiquidity(params);

        if (positionInfo.token0.balanceOf(address(this)) > 0)
            positionInfo.token0.transfer(
                owner,
                positionInfo.token0.balanceOf(address(this))
            );

        if (positionInfo.token1.balanceOf(address(this)) > 0)
            positionInfo.token1.transfer(
                owner,
                positionInfo.token1.balanceOf(address(this))
            );
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
                amount0Min: 1000,
                amount1Min: 1000,
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

    /*

    function collectAndAdd(uint256 uniV3PositionID) public {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 poolFee,
            int24 tickLower,
            int24 tickUpper,
            ,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(uniV3PositionID);

        (uint256 amount0, uint256 amount1) = _collect(uniV3PositionID);

        _swapAndIncrease(
            uniV3PositionID,
            token0,
            token1,
            poolFee,
            amount0,
            amount1,
            tickLower,
            tickUpper
        );
    }

    */

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

    /*
    function _swapAndIncrease(
        uint256 uniV3PositionID,
        address token0,
        address token1,
        uint24 poolFee,
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) private {
        (uint160 sp, , , , , , ) = IUniswapV3Pool(
            factory.getPool(token0, token1, poolFee)
        ).slot0();

        (
            uint256 x_final,
            uint256 y_final,
            bool is0To1,
            uint256 amountIn
        ) = getAmountsForAddingLiquidity(
                amount0,
                amount1,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                sp,
                1
            );

        swapExactInput(
            is0To1 ? token0 : token1,
            is0To1 ? token1 : token0,
            amountIn,
            poolFee
        );

        TransferHelper.safeApprove(
            address(token0),
            address(nonfungiblePositionManager),
            x_final
        );
        TransferHelper.safeApprove(
            address(token1),
            address(nonfungiblePositionManager),
            y_final
        );

        nonfungiblePositionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams(
                uniV3PositionID,
                x_final,
                y_final,
                0,
                0,
                block.timestamp
            )
        );
    }

    */

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
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountOut);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountIn = swapRouter.exactOutputSingle(params);
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

    /*

    function getY(
        uint160 sa,
        uint160 sb,
        uint160 sp
    ) public view returns (uint256) {
        uint256 a = FullMath.mulDiv(10 ** 18, sp, (sb - sp));
        uint256 b = FullMath.mulDiv(sb, (sp - sa), 2 ** 96);
        return FullMath.mulDiv(a, b, 2 ** 96);
    }

    function getAmountsForAddingLiquidity(
        uint256 x0,
        uint256 y0,
        uint160 sa,
        uint160 sb,
        uint160 sp,
        uint256 p
    )
        public
        view
        returns (uint256 x_final, uint256 y_final, bool is0to1, uint amountIn)
    {
        uint256 y_unit = getY(sa, sb, sp);
        uint256 v_unit = (p / 10 ** 18) + (y_unit / 10 ** 18);
        uint256 v_total = FullMath.mulDiv(x0, p, 10 ** 18) + y0;
        x_final = v_total / v_unit;
        y_final = FullMath.mulDiv(x_final, y_unit, 10 ** 18);
        is0to1 = x0 - x_final > 0;
        amountIn = is0to1 ? x0 - x_final : y0 - y_final;
    }

    */
}
