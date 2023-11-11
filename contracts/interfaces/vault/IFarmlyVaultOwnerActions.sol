pragma solidity >=0.5.0;

/// @title Permissioned vault actions
/// @notice Contains vault methods that may only be called by the vault owner
interface IFarmlyVaultOwnerActions {
    /// @notice Set the borrower can be borrow
    /// @param _borrower Borrower address to be permissioned
    function addBorrower(address _borrower) external;

    /// @notice Set the borrower can not be borrow
    /// @param _borrower Borrower address to be not permissioned
    function removeBorrower(address _borrower) external;
}
