pragma solidity >=0.5.0;
import "./IFarmlyUniV3Executor.sol";
import "./IFarmlyVault.sol";
import "../library/FarmlyStructs.sol";

interface IFarmlyPositionManager {
    struct SlippageProtection {
        uint256 minPositionUSDValue;
        uint256 maxLeverageTolerance; // 1000000 = 1x
    }

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

    struct CreatePositionParams {
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        VaultInfo vault0;
        VaultInfo vault1;
        FarmlyStructs.PositionInfo positionInfo;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct IncreasePositionParams {
        uint256 positionID;
        IFarmlyUniV3Executor executor;
        uint amount0;
        uint amount1;
        uint debtAmount0;
        uint debtAmount1;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct DecreasePositionParams {
        IFarmlyUniV3Executor executor;
        uint positionID;
        uint24 decreasingPercent;
    }

    struct CollectFeesParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    struct CollectAndIncreaseParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
        uint256 debt0;
        uint256 debt1;
        FarmlyStructs.SwapInfo swapInfo;
        SlippageProtection slippage;
    }

    struct ClosePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }

    struct LiquidatePositionParams {
        IFarmlyUniV3Executor executor;
        uint256 positionID;
    }
}
