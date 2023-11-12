pragma solidity >=0.5.0;

/// @title Events emitted by position manager
/// @notice Contains all events emitted by the position manager
interface IFarmlyPositionManagerEvents {
    /// @notice Emitted when the new position created
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    /// @param debtAmount0 The new debt amount of token0
    /// @param debtAmount1 The new debt amount of token1
    event PositionCreated(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );

    /// @notice Emitted when the existing position increased
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    /// @param debtAmount0 The new debt amount of token0
    /// @param debtAmount1 The new debt amount of token1
    event PositionIncreased(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );

    /// @notice Emitted when the existing position decreased
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The decreased amount of token0
    /// @param amount1 The decreased amount of token1
    /// @param debtAmount0 The repaid debt amount of token0
    /// @param debtAmount1 The repaid debt amount of token1
    event PositionDecreased(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );

    /// @notice Emitted when the existing position rewards collected
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The collected amount of token0
    /// @param amount1 The collected amount of token1
    event FeesCollected(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the existing position rewards collected and increased
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param collectedAmount0 The collected amount of token0
    /// @param collectedAmount1 The collected amount of token1
    /// @param amount0 The increased amount of token0
    /// @param amount1 The increased amount of token1
    /// @param debtAmount0 The new debt amount of token0
    /// @param debtAmount1 The new debt amount of token1
    event FeesCollectedAndPositionIncreased(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 collectedAmount0,
        uint256 collectedAmount1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );

    /// @notice Emitted when the existing position closed
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    /// @param debtAmount0 The repaid debt amount of token0
    /// @param debtAmount1 The repaid debt amount of token1
    event PositionClosed(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );

    /// @notice Emitted when the existing position liquidated
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param positionID Position id of position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    /// @param debtAmount0 The repaid debt amount of token0
    /// @param debtAmount1 The repaid debt amount of token1
    event PositionLiquidated(
        uint256 indexed uniV3PositionID,
        uint256 positionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 debtAmount0,
        uint256 debtAmount1
    );
}
