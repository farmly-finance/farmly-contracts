pragma solidity >=0.5.0;
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./IFarmlyPriceConsumer.sol";

import "./IFarmlyUniV3Executor.sol";

/// @title Interface of Farmly Uniswap V3 Reader
/// @notice Contract interface for reading information of positions on Uniswap V3
interface IFarmlyUniV3Reader {
    /// @notice Uniswap V3 NFT Positions Contract
    /// @dev Uniswap Uniswap contract used to manage NFT positions.
    /// @return Returns the INonfungiblePositionManager contract.
    function nonfungiblePositionManager()
        external
        view
        returns (INonfungiblePositionManager);

    /// @notice Uniswap Pool Factory
    /// @dev Used to access the pools on Uniswap.
    /// @return Returns the IUniswapV3Factory contract.
    function factory() external view returns (IUniswapV3Factory);

    /// @notice Farmly Price Consumer
    /// @dev Used to access the prices of tokens.
    /// @return Returns the IFarmlyPriceConsumer contract.
    function farmlyPriceConsumer() external view returns (IFarmlyPriceConsumer);

    /// @notice Returns token amounts of position
    /// @dev Calculates token amounts based on the current pool price.
    /// @param uniV3PositionID Uniswap V3 position ID
    /// @return amount0 The token0 amount of the position
    /// @return amount1 The token1 amount of the position
    function getPositionAmounts(
        uint256 uniV3PositionID
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Returns the Uniswap V3 position info
    /// @param uniV3PositionID Uniswap V3 position ID
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

    /// @notice Returns the Uniswap V3 position dollar value
    /// @param uniV3PositionID Uniswap V3 position ID
    /// @return token0USD The token0 amount in dollars of the position
    /// @return token1USD The token1 amount in dollars of the position
    /// @return totalUSD The total amount in dollars of the position
    function getPositionUSDValue(
        uint256 uniV3PositionID
    )
        external
        view
        returns (uint256 token0USD, uint256 token1USD, uint256 totalUSD);

    /// @notice Returns token amount of position for add
    /// @param positionInfo Position info to be created
    function getAmountsForAdd(
        IFarmlyUniV3Executor.PositionInfo memory positionInfo
    )
        external
        view
        returns (
            IFarmlyUniV3Executor.SwapInfo memory swapInfo,
            uint256 amount0Add,
            uint256 amount1Add
        );
}
