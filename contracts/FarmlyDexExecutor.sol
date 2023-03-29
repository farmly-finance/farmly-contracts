pragma solidity >=0.5.0;
import "@openzeppelin/contracts/utils/math/Math.sol";

contract FarmlyDexExecutor {
    using Math for uint;

    function getOptimalSwapAmount(
        uint256 aA,
        uint256 aB,
        uint256 rA,
        uint256 rB,
        uint256 pF // 25
    ) internal pure returns (uint256 swapAmount, bool isAB) {
        if (aA * rB >= aB * rA) {
            swapAmount = _getOptimalSwapAmount(aA, aB, rA, rB, pF);
            isAB = false;
        } else {
            swapAmount = _getOptimalSwapAmount(aB, aA, rB, rA, pF);
            isAB = true;
        }
    }

    function _getOptimalSwapAmount(
        uint256 aA,
        uint256 aB,
        uint256 rA,
        uint256 rB,
        uint256 pF
    ) internal pure returns (uint256 swapAmount) {
        require(aA * rB >= aB * rA, "BA");
        uint256 a = 1e4 - pF;
        uint256 b = (2e4 - pF) * rA;
        uint256 _c = (aA * rB) - (aB * rA);
        uint256 c = ((_c * 1e4) / (aB + rB)) * rA;

        uint256 d = a * c * 4;
        uint256 e = ((b * b) + d).sqrt();

        return ((e - b) / (2 * a));
    }
}
/* 

  uint256 a = 9975;
    uint256 b = uint256(19975).mul(resA);
    uint256 _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint256 c = _c.mul(10000).div(amtB.add(resB)).mul(resA);

    uint256 d = a.mul(c).mul(4);
    uint256 e = AlpacaMath.sqrt(b.mul(b).add(d));

    uint256 numerator = e.sub(b);
    uint256 denominator = a.mul(2);

    return numerator.div(denominator);

    */
