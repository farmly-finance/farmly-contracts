pragma solidity >=0.5.0;
import "node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FarmlyBorrower {
    using SafeMath for uint;

    function _update() public {}

    function getUtilization() public view returns (uint256) {}

    function deposit() public {}

    function withdraw() public {}

    function totalToken() public view returns (uint256) {}

    function pendingInterest() public view returns (uint256) {}

    function addBorrower() public {}

    function removeBorrower() public {}
}
