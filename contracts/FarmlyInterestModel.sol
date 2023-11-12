pragma solidity >=0.5.0;

import "./interfaces/IFarmlyInterestModel.sol";

import "./libraries/FarmlyFullMath.sol";

contract FarmlyInterestModel is IFarmlyInterestModel {
    uint256 public immutable ONE_YEAR = 365 days;

    /// @inheritdoc IFarmlyInterestModel
    uint256 public immutable override UTILIZATION_RANGE_1 = 70e18;
    /// @inheritdoc IFarmlyInterestModel
    uint256 public immutable override UTILIZATION_RANGE_2 = 90e18;
    /// @inheritdoc IFarmlyInterestModel
    uint256 public immutable override UTILIZATION_RANGE_3 = 100e18;

    /// @inheritdoc IFarmlyInterestModel
    function getUtilization(
        uint256 debt,
        uint256 total
    ) public view override returns (uint256 utilization) {
        if (total == 0) {
            return 0;
        }

        return FarmlyFullMath.mulDiv(debt, 100e18, total);
    }

    /// @inheritdoc IFarmlyInterestModel
    function getBorrowAPR(
        uint256 debt,
        uint256 total
    ) external view override returns (uint256 borrowAPR) {
        if (total == 0) {
            return 0;
        }
        uint256 utilization = getUtilization(debt, total);
        // 0%-20%
        if (utilization < UTILIZATION_RANGE_1) {
            return
                FarmlyFullMath.mulDiv(utilization, 20e18, UTILIZATION_RANGE_1) /
                ONE_YEAR;
        }
        // 20%
        else if (utilization < UTILIZATION_RANGE_2) {
            return 20e18 / ONE_YEAR;
        }
        // 20%-40%
        else if (utilization < UTILIZATION_RANGE_3) {
            return
                (20e18 +
                    ((utilization - UTILIZATION_RANGE_2) * (40e18 - (20e18))) /
                    (UTILIZATION_RANGE_3 - (UTILIZATION_RANGE_2))) / ONE_YEAR;
        }
        // 40%-100%
        else {
            return 40e18 / ONE_YEAR;
        }
    }
}
