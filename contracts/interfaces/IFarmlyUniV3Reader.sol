pragma solidity >=0.5.0;

interface IFarmlyUniV3Reader {
    function getPositionAmounts(
        uint256 uniV3PositionID
    ) external view returns (uint256 amount0, uint256 amount1);

    function getPositionInfo(
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

    function getPositionUSDValue(
        uint256 uniV3PositionID
    )
        external
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD);
}
