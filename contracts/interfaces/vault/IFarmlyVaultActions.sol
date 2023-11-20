pragma solidity >=0.5.0;

/// @title Permissionless vault actions
/// @notice Contains vault methods that can be called by anyone
interface IFarmlyVaultActions {
    /// @notice Vault lending function
    /// @dev It mints the flyToken that is the share for the lender.
    /// mint amount = amount * totalSupply() / (totalToken() - amount)
    /// On the first mint transaction, mints share mint up to the amount.
    /// @param amount Amount of tokens to lend
    function deposit(uint256 amount) external;

    /// @notice Withdrawal function for given debt with earned interest
    /// @dev The user's share of the flyToken is burned and
    /// the corresponding token amount is paid out to the user.
    /// token amount = amount * totalToken() / totalSupply()
    /// @param amount Amount of flyTokens to withdraw
    function withdraw(uint256 amount) external;

    /// @notice Borrowing function for vault
    /// @dev Can be borrowed while the vault balance is sufficient.
    /// Transfers the amount borrowed to the user.
    /// It can only be called by borrowers.
    /// @param amount Amount of tokens to borrow
    /// @param to Address to transfer tokens
    /// @return Returns debt share
    function borrow(uint256 amount, address to) external returns (uint256);

    /// @notice Close function for closing debt
    /// @dev The amount to be repaid is calculated
    /// and tokens are transferred from the user.
    /// It can only be called by borrowers.
    /// @param amount Amount of debt share to be repaid
    /// @return Returns the amount of debt paid.
    function close(uint256 amount) external returns (uint256);
}
