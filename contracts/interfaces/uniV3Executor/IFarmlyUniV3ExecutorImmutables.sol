pragma solidity >=0.5.0;
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "../IFarmlyConfig.sol";
import "../IFarmlyUniV3Reader.sol";

/// @title Uniswap V3 Executor state that never changes
/// @notice These parameters are fixed for a executor, they are fixed forever.
interface IFarmlyUniV3ExecutorImmutables {
    /// @notice Uniswap V3 NFT Positions Contract
    /// @dev Uniswap Uniswap contract used to manage NFT positions.
    /// @return Returns the INonfungiblePositionManager contract.
    function nonfungiblePositionManager()
        external
        view
        returns (INonfungiblePositionManager);

    /// @notice Uniswap Swap Router
    /// @dev It is used for swap transactions in Uniswap V3 pools.
    /// @return Returns the ISwapRouter contract.
    function swapRouter() external view returns (ISwapRouter);

    /// @notice Uniswap Pool Factory
    /// @dev Used to access the pools on Uniswap.
    /// @return Returns the IUniswapV3Factory contract.
    function factory() external view returns (IUniswapV3Factory);

    /// @notice Farmly Protocol Configrations
    /// @dev Used to access the current protocol configurations of Farmly Finance.
    /// @return Returns the IFarmlyConfig contract.
    function farmlyConfig() external view returns (IFarmlyConfig);

    /// @notice Farmly Uniswap V3 Reader
    /// @dev Used to read the open position information on the Uniswap.
    /// @return Returns the IFarmlyUniV3Reader contract.
    function farmlyUniV3Reader() external view returns (IFarmlyUniV3Reader);
}
