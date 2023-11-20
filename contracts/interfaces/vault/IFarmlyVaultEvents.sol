pragma solidity >=0.5.0;

/// @title Events emitted by a vault
/// @notice Contains all events emitted by the vault
interface IFarmlyVaultEvents {
    /// @notice Emitted when a new deposit is made.
    /// @param amount Deposited amount
    /// @param mintedAmount Minted flyToken amount
    event Deposit(uint256 amount, uint256 mintedAmount);

    /// @notice Emitted when a new withdraw is made.
    /// @param amount Burned flyToken amount
    /// @param withdrawnAmount Withrawn amount
    event Withdraw(uint256 amount, uint256 withdrawnAmount);

    /// @notice Emitted when a new borrow is made.
    /// @param borrower The borrower address
    /// @param amount Debt amount
    /// @param debtShare Debt share amount
    event Borrow(address indexed borrower, uint256 amount, uint256 debtShare);

    /// @notice Emitted when a new repay is made.
    /// @param amount Repaid debt share amount
    /// @param paidAmount Repaid debt amount
    event Repay(uint256 amount, uint256 paidAmount);

    /// @notice Emitted when a borrower state changed.
    /// @param borrower The borrower address
    /// @param status The borrower status
    event Borrower(address indexed borrower, bool indexed status);
}
