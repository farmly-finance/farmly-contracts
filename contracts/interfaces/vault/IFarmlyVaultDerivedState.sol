pragma solidity >=0.5.0;

/// @title Vault state that is not stored
/// @notice Contains derived states that do not need to be stored on the blockchain.
interface IFarmlyVaultDerivedState {
    /// @notice Total amount of tokens on the contract
    /// @dev It should be calculated by adding the total amount of debt.
    /// @return Returns the total amount of tokens on the contract.
    function totalToken() external view returns (uint256);

    /// @notice Calculates the pending interest amount
    /// @dev Pending interest is calculated from the timestamp
    /// of the last transaction to the current timestamp.
    /// Borrowing interest is calculated using the Vault's interest model.
    /// @param value Input amount of interest to be calculated
    /// @return Pending interest amount
    function pendingInterest(uint256 value) external view returns (uint256);

    /// @notice Converts the debt share into debt.
    /// @dev debt = debt share * (total debt + pending interest) / total debt share
    /// @param debtShare Debt share to be calculated
    /// @return Calculated debt
    function debtShareToDebt(uint256 debtShare) external view returns (uint256);

    /// @notice Converts the debt into debt share
    /// @dev debt share = debt * total debt share / (total debt + pending interest)
    /// @param debt Debt to be calculated
    /// @return Calculated debt share
    function debtToDebtShare(uint256 debt) external view returns (uint256);
}
