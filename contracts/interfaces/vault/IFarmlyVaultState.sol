pragma solidity >=0.5.0;

/// @title Vault state that can change
/// @notice These methods form the state of the vault. It can change multiple times
/// per transaction without limit.
interface IFarmlyVaultState {
    /// @notice Total debt borrowed from the vault
    /// @return Returns the total amount of debt
    function totalDebt() external view returns (uint256);
}
