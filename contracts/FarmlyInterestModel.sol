pragma solidity >=0.5.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./library/FarmlyFullMath.sol";

contract FarmlyInterestModel {
    using Math for uint;
    uint256 public constant ONE_YEAR = 365 days;

    uint256 public constant UTILIZATION_RAGE_1 = 70e18;
    uint256 public constant UTILIZATION_RAGE_2 = 90e18;
    uint256 public constant UTILIZATION_RAGE_3 = 100e18;

    function getUtilization(
        uint256 debt,
        uint256 total
    ) internal pure returns (uint256) {
        if (total == 0) {
            return 0;
        }
        return (FarmlyFullMath.mulDiv(debt, 100e18, total));
    }

    function getBorrowAPR(
        uint256 debt,
        uint256 total
    ) public pure returns (uint256) {
        if (total == 0) {
            return 0;
        }
        uint256 utilization = getUtilization(debt, total);
        if (utilization < UTILIZATION_RAGE_1) {
            return
                (
                    FarmlyFullMath.mulDiv(
                        utilization,
                        20e18,
                        UTILIZATION_RAGE_1
                    )
                ) / ONE_YEAR;
        } else if (utilization < UTILIZATION_RAGE_2) {
            return 20e18 / ONE_YEAR;
        } else if (utilization < UTILIZATION_RAGE_3) {
            return
                (20e18 +
                    ((utilization - UTILIZATION_RAGE_2) * (40e18 - (20e18))) /
                    (UTILIZATION_RAGE_3 - (UTILIZATION_RAGE_2))) / ONE_YEAR;
        } else {
            return 40e18 / ONE_YEAR;
        }
    }
}
