pragma solidity >=0.5.0;
import "../library/FarmlyStructs.sol";

interface IFarmlyUniV3Executor {
    function execute(
        address owner,
        uint256 amount0Has,
        uint256 amount1Has,
        FarmlyStructs.PositionInfo memory positionInfo,
        FarmlyStructs.SwapInfo memory swapInfo
    ) external returns (uint256 tokenId);

    function increase(
        uint256 uniV3PositionID,
        address owner,
        uint256 amount0Has,
        uint256 amount1Has,
        FarmlyStructs.SwapInfo memory swapInfo
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function decrease(
        uint256 uniV3PositionID,
        uint24 liquidityPercent,
        uint256 debt0,
        uint256 debt1
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        );

    function collect(
        uint256 uniV3PositionID,
        address owner
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1
        );

    function close(
        uint256 uniV3PositionID,
        uint256 debt0,
        uint256 debt1
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidity,
            address token0,
            address token1,
            uint24 poolFee
        );

    function getPositionAmounts(
        uint256 uniV3PositionID
    ) external view returns (uint256 amount0, uint256 amount1);

    function getPositionData(
        uint256 uniV3PositionID
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity
        );
}
