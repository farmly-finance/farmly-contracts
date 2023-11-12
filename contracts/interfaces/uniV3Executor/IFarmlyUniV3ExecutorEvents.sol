pragma solidity >=0.5.0;

/// @title Events emitted by Uniswap V3 executor
/// @notice Contains all events emitted by the Uniswap V3 executor
interface IFarmlyUniV3ExecutorEvents {
    /// @notice Emitted when the executed
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The added amount of token0
    /// @param amount1 The added amount of token1
    event Execute(
        uint256 indexed uniV3PositionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the position increased
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The increased amount of token0
    /// @param amount1 The increased amount of token1
    event Increase(
        uint256 indexed uniV3PositionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the position decreased
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The decreased amount of token0
    /// @param amount1 The decreased amount of token1
    event Decrease(
        uint256 indexed uniV3PositionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the position rewards collected
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The collected amount of token0
    /// @param amount1 The collected amount of token1
    event Collect(
        uint256 indexed uniV3PositionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the position closed
    /// @param uniV3PositionID Token id of Uniswap V3 position
    /// @param token0 The token0 contract address of position
    /// @param token1 The token1 contract address of position
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    event Close(
        uint256 indexed uniV3PositionID,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1
    );
}
