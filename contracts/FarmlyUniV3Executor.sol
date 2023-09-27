pragma solidity >=0.5.0;
pragma abicoder v2;

import "./library/LiquidityAmountsLib.sol";
import "./library/FarmlyFullMath.sol";
import "./library/FarmlyStructs.sol";
import "./library/FarmlyTransferHelper.sol";
import "./interfaces/IFarmlyConfig.sol";
import "./interfaces/IFarmlyUniV3Reader.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";

contract FarmlyUniV3Executor is IERC721Receiver, LiquidityAmountsLib {
    INonfungiblePositionManager public constant nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Factory public constant factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IFarmlyConfig public farmlyConfig =
        IFarmlyConfig(0x6E1A6Ac7A385a5C4c085C71A48B8C61CeBAf4a1b);

    IFarmlyUniV3Reader public farmlyUniV3Reader =
        IFarmlyUniV3Reader(0x8727Ded114fE87E8aEC40E51D29989fD66ccE622);

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
        if (amount0Has > 0)
            FarmlyTransferHelper.safeTransferFrom(
                positionInfo.token0,
                msg.sender,
                address(this),
                amount0Has
            );
        if (amount1Has > 0)
            FarmlyTransferHelper.safeTransferFrom(
                positionInfo.token1,
                msg.sender,
                address(this),
                amount1Has
            );

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
            positionInfo.token0 == pool.token0()
                ? IERC20Metadata(positionInfo.token0)
                : IERC20Metadata(positionInfo.token1),
            positionInfo.token1 == pool.token1()
                ? IERC20Metadata(positionInfo.token1)
                : IERC20Metadata(positionInfo.token0),
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
        (address token0, address token1, uint24 fee, , , ) = farmlyUniV3Reader
            .getPositionInfo(uniV3PositionID);

        FarmlyTransferHelper.safeTransferFrom(
            token0,
            msg.sender,
            address(this),
            amount0Has
        );

        FarmlyTransferHelper.safeTransferFrom(
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
    }

    function collect(
        uint256 uniV3PositionID,
        address owner
    )
        public
        returns (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        )
    {
        (amount0, amount1) = _collect(uniV3PositionID, address(this));

        (, , token0, token1, , , , , , , , ) = nonfungiblePositionManager
            .positions(uniV3PositionID);

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

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

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

        // The call to `exactInputSingle` executes the swap.
        amountIn = swapRouter.exactOutputSingle(params);
        FarmlyTransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
    }

    function add(
        address owner,
        IERC20Metadata token0,
        IERC20Metadata token1,
        uint24 poolFee,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96
    ) private returns (uint256 tokenId) {
        FarmlyTransferHelper.safeApprove(
            address(token0),
            address(nonfungiblePositionManager),
            token0.balanceOf(address(this))
        );
        FarmlyTransferHelper.safeApprove(
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
            FarmlyTransferHelper.safeTransfer(
                address(token0),
                owner,
                token0.balanceOf(address(this))
            );

        if (token1.balanceOf(address(this)) > 0)
            FarmlyTransferHelper.safeTransfer(
                address(token1),
                owner,
                token1.balanceOf(address(this))
            );
    }
}
