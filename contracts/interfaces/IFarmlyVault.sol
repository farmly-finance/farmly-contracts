pragma solidity >=0.5.0;

interface IFarmlyVault {
    function borrow(uint256 amount) external returns (uint);

    function close(uint256 debtShare) external returns (uint256);

    function pendingInterest(uint256 value) external view returns (uint256);

    function totalDebt() external view returns (uint);

    function totalDebtShare() external view returns (uint);
}
