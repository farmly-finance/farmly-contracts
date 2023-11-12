pragma solidity >=0.5.0;

/// @title Permissioned position manager actions
/// @notice Contains position manager methods that may
/// only be called by the position manager owner
interface IFarmlyPositionManagerOwnerActions {
    /// @notice Pauses the contract
    /// @dev Pauses the opening new positions
    // and the increase of existing positions.
    function pause() external;

    /// @notice Unpauses the contract
    /// @dev Unpauses the opening new positions
    // and the increase of existing positions.
    function unpause() external;
}
