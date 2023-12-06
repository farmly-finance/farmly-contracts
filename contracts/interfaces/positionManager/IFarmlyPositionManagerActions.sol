pragma solidity >=0.5.0;
import "./IFarmlyPositionManagerState.sol";
import "../IFarmlyUniV3Executor.sol";

/// @title Permissionless position manager actions
/// @notice Contains position manager methods that can be called by anyone
interface IFarmlyPositionManagerActions {
    struct SlippageProtection {
        uint256 minPositionUSDValue;
        uint256 maxLeverageTolerance; // 1000000 = 1x
    }
    struct CreatePositionParams {
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        IFarmlyPositionManagerState.VaultInfo vault0;
        IFarmlyPositionManagerState.VaultInfo vault1;
        IFarmlyUniV3Executor.PositionInfo positionInfo;
        SlippageProtection slippage;
    }

    /// @notice Creates a new position.
    /// @dev Debts are taken from vaults,
    /// position is created by calling IFarmlyUniV3Executor.
    /// @param params The parameters necessary for the create position,
    /// encoded as `CreatePositionParams` in calldata
    function createPosition(CreatePositionParams calldata params) external;

    struct IncreasePositionParams {
        uint256 positionID;
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        uint debtAmount0;
        uint debtAmount1;
        SlippageProtection slippage;
    }

    /// @notice Increases the existing position.
    /// @dev Debts are taken from vaults,
    /// position is increased by calling IFarmlyUniV3Executor.
    /// @param params The parameters necessary for the increase position,
    /// encoded as `IncreasePositionParams` in calldata
    function increasePosition(IncreasePositionParams calldata params) external;

    struct DecreasePositionParams {
        IFarmlyUniV3Executor executor;
        uint positionID;
        uint24 decreasingPercent;
    }

    /// @notice Decreases the existing position.
    /// @dev Position is decreased by calling IFarmlyUniV3Executor.
    /// Debts are repaid up to the reduced percentage.
    /// @param params The parameters necessary for the decrease position,
    /// encoded as `DecreasePositionParams` in calldata
    function decreasePosition(DecreasePositionParams calldata params) external;

    struct CollectFeesParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    /// @notice Collects the trading fees earned on the existing position.
    /// @dev Fees are collected by calling IFarmlyUniV3Executor.
    /// @param params The parameters necessary for the collect fees,
    /// encoded as `CollectFeesParams` in calldata
    function collectFees(CollectFeesParams calldata params) external;

    struct CollectAndIncreaseParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
        uint256 debt0;
        uint256 debt1;
        SlippageProtection slippage;
    }

    /// @notice Collects the trading fees earned on the existing position
    /// and increases this position.
    /// @dev Fees are collected by calling IFarmlyUniV3Executor.
    /// Position is increased by calling IFarmlyUniV3Executor.
    /// @param params The parameters necessary for the collect fees and increase position,
    /// encoded as `CollectAndIncreaseParams` in calldata
    function collectAndIncrease(
        CollectAndIncreaseParams calldata params
    ) external;

    struct ClosePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    /// @notice Closes the existing position.
    /// @dev Position is closed by calling IFarmlyUniV3Executor.
    /// Debts are repaid.
    /// @param params The parameters necessary for the close position,
    /// encoded as `ClosePositionParams` in calldata
    function closePosition(ClosePositionParams calldata params) external;

    struct LiquidatePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    /// @notice Liquidates the existing position.
    /// @dev If the position exceeds the liquidation threshold, the position can be liquidated.
    /// Position is liquidated by calling IFarmlyUniV3Executor.
    /// Debts are repaid.
    /// @param params The parameters necessary for the liquidate position,
    /// encoded as `LiquidatePositionParams` in calldata
    function liquidatePosition(
        LiquidatePositionParams calldata params
    ) external;
}
