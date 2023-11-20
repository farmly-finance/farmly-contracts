pragma solidity >=0.5.0;
import "./uniV3Executor/IFarmlyUniV3ExecutorImmutables.sol";
import "./uniV3Executor/IFarmlyUniV3ExecutorEvents.sol";

/// @title The interface for the Farmly Uniswap V3 Executor
/// @notice Functions for the management of positions on Uniswap V3.
/// @dev Uniswap V3 position NFTs are stored in this contract.
/// It can only be called by the Farmly Position Manager contract.
/// It acts as a bridge between Uniswap V3 and Farmly Finance.
interface IFarmlyUniV3Executor is
    IFarmlyUniV3ExecutorImmutables,
    IFarmlyUniV3ExecutorEvents
{
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

    /// @notice Creates new Uniswap V3 Position
    /// @dev Creates a new Uniswap V3 position by calling
    /// the Uniswap Nonfungible Position Manager contract.
    /// Executes a swap to build the position at the correct rates.
    /// Returns any excess tokens to the owner when the position is created.
    /// @param owner Address of the user who created the position.
    /// Not the Farmly position manager!
    /// @param positionInfo All information of the Uniswap V3 position to be created.
    /// @param swapInfo Information about the swap transaction.
    /// @return tokenId Returns the nft tokenId of the created Uniswap V3 position.
    /// It also represents the Uniswap V3 position id.
    function execute(
        address owner,
        PositionInfo memory positionInfo,
        SwapInfo memory swapInfo
    ) external returns (uint256 tokenId);

    /// @notice Increases the existing Uniswap V3 Position.
    /// @dev Increases the existing Uniswap V3 Position by calling
    /// the Uniswap Nonfungible Position Manager contract.
    /// Executes a swap to increase the position at the correct rates.
    /// Returns any excess tokens to the owner when the position is increased.
    /// @param uniV3PositionID Token id of Uniswap V3 position to be increased.
    /// @param owner Address of the position owner
    /// @param swapInfo Information about the swap transaction.
    /// @return liquidity Amount of position liquidity increased.
    /// @return amount0 Amount of token0 increased
    /// @return amount1 Amount of token1 increased
    function increase(
        uint256 uniV3PositionID,
        address owner,
        SwapInfo memory swapInfo
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the existing Uniswap V3 Position.
    /// @dev Decreases the existing Uniswap V3 Position by calling
    /// the Uniswap Nonfungible Position Manager contract.
    /// If the reduced amount is less than the amount of debt0 and debt1,
    /// a swap transaction is made to balance each other.
    /// @param uniV3PositionID Token id of Uniswap V3 position to be increased.
    /// @param liquidityPercent Percentage amount of liquidity to be reduced.
    /// @param debt0 Desired minimum amount of token0
    /// @param debt1 Desired minimum amount of token1
    /// @return amount0 Amount of token0 decreased
    /// @return amount1 Amount of token1 decreased
    /// @return liquidity Position liquidity amount before reduction
    /// @return token0 The token0 contract address of the position
    /// @return token1 The token1 contract address of the position
    /// @return poolFee Fee rate of the pool
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

    /// @notice Collects the trading fees earned on the existing Uniswap V3 Position.
    /// @dev Collects the trading fees earned on the existing Uniswap V3 position
    /// by calling the Uniswap Nonfungible Position Manager contract.
    /// Uniswap performance fee amount should be sent to the fee address
    /// according to the current protocol configuration.
    /// @param uniV3PositionID Token id of Uniswap V3 position to be collected.
    /// @param owner Address of the position owner
    /// @return amount0 Amount of token0 collected
    /// @return amount1 Amount of token1 collected
    /// @return token0 The token0 contract address of the position
    /// @return token1 The token1 contract address of the position
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

    /// @notice Completely closes the existing Uniswap V3 Position.
    /// @dev Completely closes the existing Uniswap V3 Position
    /// by calling the Uniswap Nonfungible Position Manager contract.
    /// If the closed amount is less than the amount of debt0 and debt1,
    /// a swap transaction is made to balance each other.
    /// @param uniV3PositionID Token id of Uniswap V3 position to be closed.
    /// @param debt0 Desired minimum amount of token0
    /// @param debt1 Desired minimum amount of token1
    /// @return amount0 Amount of token0 closed position
    /// @return amount1 Amount of token1 closed position
    /// @return liquidity Liquidity amount of the closed position
    /// @return token0 The token0 contract address of the position
    /// @return token1 The token1 contract address of the position
    /// @return poolFee Fee rate of the pool
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
}
