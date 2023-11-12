pragma solidity >=0.5.0;
import "./positionManager/IFarmlyPositionManagerImmutables.sol";
import "./positionManager/IFarmlyPositionManagerState.sol";

/// @title Interface for Position Manager
/// @notice All positions opened on Farmly Finance
/// are managed through this contract.
interface IFarmlyPositionManager is
    IFarmlyPositionManagerImmutables,
    IFarmlyPositionManagerState
{

}
