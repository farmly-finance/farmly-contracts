pragma solidity >=0.5.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./library/FarmlyFullMath.sol";

contract FarmlyConfig {
    using Math for uint;
    uint256 public constant ONE_YEAR = 365 days;

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
        if (utilization < 70e18) {
            return
                (FarmlyFullMath.mulDiv(utilization, 20e18, 70e18)) / ONE_YEAR;
        } else if (utilization < 90e18) {
            return 20e18 / ONE_YEAR;
        } else if (utilization < 100e18) {
            return
                (20e18 +
                    ((utilization - 90e18) * (40e18 - (20e18))) /
                    (100e18 - (90e18))) / ONE_YEAR;
        } else {
            return 40e18 / ONE_YEAR;
        }
    }
}
