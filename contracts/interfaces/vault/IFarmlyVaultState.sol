pragma solidity >=0.5.0;

/// @title Vault state that can change
/// @notice These methods form the state of the vault. It can change multiple times
/// per transaction without limit.
interface IFarmlyVaultState {
    /// @notice Total debt borrowed from the vault
    /// @dev Before each transaction, the amount of accumulated
    /// interest must be calculated and added to it.
    /// @return Returns the total amount of debt
    function totalDebt() external view returns (uint256);

    /// @notice Total debt shares
    /// @dev The debt share is calculated for each borrower when borrowing.
    /// The amount to be repaid is calculated as:
    /// user's debt share * total debt amount / total debt share.
    /// The total debt share is the sum of all borrowers shares.
    /// It can be changed during borrowing and repayment.
    /// @return Returns the total amount of debt shares
    function totalDebtShare() external view returns (uint256);

    /// @notice Timestamp of the last transaction.
    /// @dev It is updated before each transaction.
    /// @return Returns the timestamp of the last transaction.
    function lastAction() external view returns (uint256);

    /// @notice Contract addresses that can borrow
    /// @dev Can only be changed by the owner.
    /// @param borrower Borrower contract address
    /// @return Can it borrow? true: yes, false: no
    function borrower(address borrower) external view returns (bool);
}
