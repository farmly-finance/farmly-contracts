pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library FarmlyStructs {
    struct PositionInfo {
        address token0;
        address token1;
        uint24 poolFee;
        uint160 sqrtRatioAX96;
        uint160 sqrtRatioBX96;
        uint amount0Add;
        uint amount1Add;
    }

    struct SwapInfo {
        address tokenIn;
        address tokenOut;
        uint amountIn;
    }
}
