pragma solidity >=0.5.0;

interface IFarmlyInterestModel {
    function getBorrowAPR(
        uint256 debt,
        uint256 total
    ) external pure returns (uint256);
}
