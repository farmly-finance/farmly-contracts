pragma solidity >=0.5.0;
import "../IFarmlyPriceConsumer.sol";
import "../IFarmlyConfig.sol";
import "../IFarmlyUniV3Reader.sol";

/// @title Positiom manager state that never changes
/// @notice These parameters are fixed for a position manager, they are fixed forever.
/// Methods will always return the same value.
interface IFarmlyPositionManagerImmutables {
    /// @notice Farmly Price Consumer
    /// @dev Used to access the prices of tokens.
    /// @return Returns the IFarmlyPriceConsumer contract.
    function farmlyPriceConsumer() external view returns (IFarmlyPriceConsumer);

    /// @notice Farmly Protocol Configrations
    /// @dev Used to access the current protocol configurations of Farmly Finance.
    /// @return Returns the IFarmlyConfig contract.
    function farmlyConfig() external view returns (IFarmlyConfig);

    /// @notice Farmly Uniswap V3 Reader
    /// @dev Used to read the open position information on the Uniswap.
    /// @return Returns the IFarmlyUniV3Reader contract.
    function farmlyUniV3Reader() external view returns (IFarmlyUniV3Reader);
}
