pragma solidity >=0.5.0;
import "../IFarmlyVault.sol";

/// @title Position manager state that can change
/// @notice These methods form the state of the position manager. It can change multiple times
/// per transaction without limit.
interface IFarmlyPositionManagerState {
    struct VaultInfo {
        IFarmlyVault vault;
        uint debtAmount;
    }

    struct DebtInfo {
        IFarmlyVault vault;
        uint debtShare;
    }

    struct Position {
        uint uniV3PositionID;
        address owner;
        DebtInfo debt0;
        DebtInfo debt1;
    }

    /// @notice Stores position info
    /// @dev Each position must be stored when opened.
    /// @return Returns position info
    function positions(uint256) external view returns (Position memory);

    /// @notice Stores the ids of the user's positions
    /// @return Returns user's positions id
    function userPositions(address) external view returns (uint256[] memory);

    /// @notice Stores active positions
    /// @dev Stores all positions that are currently active.
    /// It is removed from here when the position is closed.
    /// @return Returns position id
    function activePositions(uint256) external view returns (uint256);

    /// @notice Next position id
    /// @dev Each time a new position is opened, it is increased by 1.
    /// Start from 1.
    /// The id of the next position.
    /// @return Returns position id
    function nextPositionID() external view returns (uint256);
}
