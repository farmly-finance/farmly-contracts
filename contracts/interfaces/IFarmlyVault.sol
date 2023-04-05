pragma solidity >=0.5.0;

interface IFarmlyVault {
    function borrow(uint256 amount) external returns (uint);

    function close(uint256 debtShare) external returns (uint256);
}
